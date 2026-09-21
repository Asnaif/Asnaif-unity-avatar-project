/**
 * NVC Recorder — Webcam Frame Capture for Body Language Analysis
 * 
 * Captures webcam frames at intervals and sends them to the Python server
 * for real-time NVC (Non-Verbal Communication) analysis using MediaPipe.
 * 
 * Called from Flutter via JS interop during avatar interviews.
 */

(function() {
    'use strict';

    var nvcStream = null;
    var nvcInterval = null;
    var nvcVideo = null;
    var nvcCanvas = null;
    var nvcCtx = null;
    var isRecording = false;
    var frameCount = 0;
    var FRAME_INTERVAL_MS = 500; // Send frame every 500ms (2 FPS for server)
    var SERVER_URL = 'http://127.0.0.1:5000';

    /**
     * Attach the webcam stream to ALL preview video elements.
     * Flutter creates video elements via platformViewRegistry with IDs like
     * 'nvc-camera-preview-0', 'nvc-camera-preview-1', etc.
     * We also search inside Shadow DOM (Flutter Web uses Shadow DOM).
     */
    function attachStreamToPreviewElements() {
        if (!nvcStream) return;

        // Search normal DOM
        var allVideos = document.querySelectorAll('video');
        allVideos.forEach(function(v) {
            if (v.id && v.id.indexOf('nvc-camera-preview') !== -1) {
                if (!v.srcObject || v.srcObject !== nvcStream) {
                    console.log('[NVC] Attaching stream to preview:', v.id);
                    v.srcObject = nvcStream;
                    v.play().catch(function(e) { 
                        console.warn('[NVC] Preview play failed:', e.message); 
                    });
                }
            }
        });

        // Search Shadow DOM (Flutter puts platform views in shadow roots)
        function searchShadowRoots(root) {
            var shadowVideos = root.querySelectorAll('video');
            shadowVideos.forEach(function(v) {
                if (v.id && v.id.indexOf('nvc-camera-preview') !== -1) {
                    if (!v.srcObject || v.srcObject !== nvcStream) {
                        console.log('[NVC] Attaching stream to shadow preview:', v.id);
                        v.srcObject = nvcStream;
                        v.play().catch(function(e) { 
                            console.warn('[NVC] Shadow preview play failed:', e.message); 
                        });
                    }
                }
            });
            // Recurse into child shadow roots
            var elements = root.querySelectorAll('*');
            for (var i = 0; i < elements.length; i++) {
                if (elements[i].shadowRoot) {
                    searchShadowRoots(elements[i].shadowRoot);
                }
            }
        }
        searchShadowRoots(document);

        // Also check flt-glass-pane shadow root
        var glassPane = document.querySelector('flt-glass-pane');
        if (glassPane && glassPane.shadowRoot) {
            searchShadowRoots(glassPane.shadowRoot);
        }
    }

    /**
     * Start NVC webcam recording.
     * Creates a hidden video element, captures webcam, and starts sending frames.
     * @param {string} sessionId - Interview session ID
     */
    window.startNVCRecording = async function(sessionId) {
        if (isRecording) {
            console.log('[NVC] Already recording');
            return;
        }

        try {
            console.log('[NVC] Starting webcam recording for session:', sessionId);

            // Request webcam access (video only, audio handled by VAPI)
            nvcStream = await navigator.mediaDevices.getUserMedia({
                video: { 
                    width: { ideal: 320 },
                    height: { ideal: 240 },
                    facingMode: 'user'
                },
                audio: false
            });

            // Create hidden video element for canvas capture
            nvcVideo = document.getElementById('nvc-video-preview');
            if (!nvcVideo) {
                nvcVideo = document.createElement('video');
                nvcVideo.id = 'nvc-video-preview';
                nvcVideo.autoplay = true;
                nvcVideo.playsInline = true;
                nvcVideo.muted = true;
                nvcVideo.style.cssText = 'position:fixed;top:0;left:0;width:1px;height:1px;opacity:0;pointer-events:none;';
                document.body.appendChild(nvcVideo);
            }
            nvcVideo.srcObject = nvcStream;
            await nvcVideo.play();

            // Create canvas for frame capture
            nvcCanvas = document.createElement('canvas');
            nvcCanvas.width = 320;
            nvcCanvas.height = 240;
            nvcCtx = nvcCanvas.getContext('2d');

            // Notify server to start NVC session
            try {
                await fetch(SERVER_URL + '/api/nvc/start', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ sessionId: sessionId })
                });
            } catch(e) {
                console.warn('[NVC] Could not notify server:', e.message);
            }

            // Start frame capture loop
            isRecording = true;
            frameCount = 0;
            nvcInterval = setInterval(function() { captureAndSendFrame(sessionId); }, FRAME_INTERVAL_MS);

            // Attach stream to preview video elements (try multiple times for Flutter)
            attachStreamToPreviewElements();
            setTimeout(attachStreamToPreviewElements, 500);
            setTimeout(attachStreamToPreviewElements, 1500);
            setTimeout(attachStreamToPreviewElements, 3000);
            setTimeout(attachStreamToPreviewElements, 5000);

            console.log('[NVC] Recording started');

            // Dispatch event for Flutter to know NVC is ready
            window.dispatchEvent(new CustomEvent('nvc-started', { detail: { sessionId: sessionId } }));

        } catch (e) {
            console.error('[NVC] Failed to start recording:', e);
            window.dispatchEvent(new CustomEvent('nvc-error', { detail: { error: e.message } }));
        }
    };

    /**
     * Stop NVC recording and clean up resources.
     */
    window.stopNVCRecording = function() {
        if (!isRecording && !nvcStream) return;

        console.log('[NVC] Stopping recording (' + frameCount + ' frames captured)');

        isRecording = false;
        if (nvcInterval) {
            clearInterval(nvcInterval);
            nvcInterval = null;
        }

        // Stop webcam tracks
        if (nvcStream) {
            nvcStream.getTracks().forEach(function(t) { t.stop(); });
            nvcStream = null;
        }

        // Clean up video element
        if (nvcVideo) {
            nvcVideo.srcObject = null;
        }

        frameCount = 0;
        console.log('[NVC] Recording stopped');
    };

    /**
     * Get the webcam MediaStream for preview display.
     * @returns {MediaStream|null}
     */
    window.getNVCStream = function() {
        return nvcStream;
    };

    /**
     * Check if NVC recording is active.
     * @returns {boolean}
     */
    window.isNVCRecording = function() {
        return isRecording;
    };

    /**
     * Force-attach the NVC stream to all preview elements.
     * Called from Flutter side if the preview appears after recording started.
     */
    window.attachNVCPreview = function() {
        attachStreamToPreviewElements();
    };

    /**
     * Capture a single frame and send to server.
     * @param {string} sessionId
     */
    async function captureAndSendFrame(sessionId) {
        if (!isRecording || !nvcVideo || nvcVideo.readyState < 2) return;

        try {
            // Draw video frame to canvas
            nvcCtx.drawImage(nvcVideo, 0, 0, nvcCanvas.width, nvcCanvas.height);

            // Convert canvas to JPEG blob
            var blob = await new Promise(function(resolve) {
                nvcCanvas.toBlob(resolve, 'image/jpeg', 0.7);
            });

            if (!blob) return;

            // Send frame to server
            var formData = new FormData();
            formData.append('sessionId', sessionId);
            formData.append('frame', blob, 'frame.jpg');

            var response = await fetch(SERVER_URL + '/api/nvc/frame', {
                method: 'POST',
                body: formData
            });

            if (response.ok) {
                var result = await response.json();
                frameCount++;

                // Re-attach stream periodically (in case Flutter recreated the element)
                if (frameCount % 10 === 1) {
                    attachStreamToPreviewElements();
                }

                // Dispatch real-time metrics event for Flutter UI
                if (result.success) {
                    window.dispatchEvent(new CustomEvent('nvc-metrics', { 
                        detail: {
                            frameNumber: frameCount,
                            faceDetected: result.face_detected,
                            eyeContact: result.eye_contact,
                            eyeScore: result.eye_score,
                            emotion: result.emotion,
                            posture: result.posture,
                            postureScore: result.posture_score,
                            handsDetected: result.hands_detected,
                            headCentered: result.head_centered
                        }
                    }));
                }
            }
        } catch (e) {
            // Silently fail on individual frames
            if (frameCount % 20 === 0) {
                console.warn('[NVC] Frame send failed (frame ' + frameCount + '):', e.message);
            }
        }
    }

    console.log('[NVC] NVC Recorder loaded');
})();
