"""
============================================================================
PDF REPORT GENERATOR — 2-Page Professional Report
============================================================================
Generates a styled 2-page PDF report from session analysis data.
Page 1: Executive Summary with radar chart and key metrics
Page 2: Detailed analysis with timeline charts and recommendations

Usage:
    from report_generator import ReportGenerator
    generator = ReportGenerator()
    generator.generate(session_summary, "report.pdf")

    # Test mode:
    python report_generator.py --test
============================================================================
"""

import os
import io
import math
import time
from typing import Dict, List

import matplotlib
matplotlib.use('Agg')  # Non-interactive backend
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.figure import Figure
import numpy as np

from reportlab.lib.pagesizes import A4
from reportlab.lib.units import inch, mm
from reportlab.lib.colors import Color, HexColor
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    Image as RLImage, PageBreak, HRFlowable, KeepTogether
)
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from reportlab.graphics.shapes import Drawing, Circle, String, Line, Rect
from reportlab.graphics import renderPDF

from .session_recorder import SessionSummary
from . import config


# ════════════════════════════════════════════════════════════
# COLOR PALETTE
# ════════════════════════════════════════════════════════════
C_PRIMARY = HexColor("#1C2345")
C_SECONDARY = HexColor("#3366CC")
C_ACCENT = HexColor("#F5A623")
C_SUCCESS = HexColor("#2EBF62")
C_WARNING = HexColor("#F28C18")
C_DANGER = HexColor("#E6402E")
C_BG_LIGHT = HexColor("#F5F7FA")
C_TEXT_DARK = HexColor("#262626")
C_TEXT_GRAY = HexColor("#666666")
C_WHITE = HexColor("#FFFFFF")


class ReportGenerator:
    """Generates a 2-page PDF performance report."""

    def __init__(self):
        self.styles = getSampleStyleSheet()
        self._setup_styles()

    def _setup_styles(self):
        """Create custom paragraph styles."""
        self.styles.add(ParagraphStyle(
            'ReportTitle', parent=self.styles['Title'],
            fontSize=22, textColor=C_PRIMARY, spaceAfter=6,
            alignment=TA_CENTER, fontName='Helvetica-Bold'))
        self.styles.add(ParagraphStyle(
            'ReportSubtitle', parent=self.styles['Normal'],
            fontSize=11, textColor=C_TEXT_GRAY, spaceAfter=16,
            alignment=TA_CENTER))
        self.styles.add(ParagraphStyle(
            'SectionHeader', parent=self.styles['Heading2'],
            fontSize=14, textColor=C_PRIMARY, spaceBefore=12,
            spaceAfter=6, fontName='Helvetica-Bold'))
        self.styles.add(ParagraphStyle(
            'MetricLabel', parent=self.styles['Normal'],
            fontSize=11, textColor=C_TEXT_GRAY, alignment=TA_CENTER,
            leading=14, spaceBefore=4))
        self.styles.add(ParagraphStyle(
            'MetricValue', parent=self.styles['Normal'],
            fontSize=22, textColor=C_PRIMARY, alignment=TA_CENTER,
            fontName='Helvetica-Bold', leading=26, spaceAfter=6))
        self.styles.add(ParagraphStyle(
            'RptBodyText', parent=self.styles['Normal'],
            fontSize=10, textColor=C_TEXT_DARK, spaceBefore=3,
            spaceAfter=3, leading=14))
        self.styles.add(ParagraphStyle(
            'RptSmallText', parent=self.styles['Normal'],
            fontSize=8, textColor=C_TEXT_GRAY))
        self.styles.add(ParagraphStyle(
            'QAQuestion', parent=self.styles['Normal'],
            fontSize=10, textColor=C_PRIMARY, spaceBefore=6,
            spaceAfter=2, fontName='Helvetica-Bold', leading=14))
        self.styles.add(ParagraphStyle(
            'QAAnswer', parent=self.styles['Normal'],
            fontSize=9, textColor=C_TEXT_DARK, spaceBefore=2,
            spaceAfter=2, leading=13))
        self.styles.add(ParagraphStyle(
            'QAFeedback', parent=self.styles['Normal'],
            fontSize=9, textColor=C_TEXT_GRAY, spaceBefore=2,
            spaceAfter=6, leading=12, fontName='Helvetica-Oblique'))
        self.styles.add(ParagraphStyle(
            'CombinedScoreTitle', parent=self.styles['Normal'],
            fontSize=12, textColor=C_TEXT_GRAY, alignment=TA_CENTER,
            spaceBefore=4, spaceAfter=2))
        self.styles.add(ParagraphStyle(
            'CombinedScoreValue', parent=self.styles['Normal'],
            fontSize=44, textColor=C_PRIMARY, alignment=TA_CENTER,
            fontName='Helvetica-Bold', spaceBefore=0, spaceAfter=12, leading=50))

    def _parse_qa_accuracy(self, qa_dict: dict) -> int:
        """Safely parse accuracy score from various LLM JSON keys, handling strings and floats."""
        for key in ["accuracy_score", "accuracy", "score", "rating", "qa_score"]:
            val = qa_dict.get(key)
            if val is not None:
                try:
                    if isinstance(val, str):
                        val = val.replace('%', '').strip()
                    return int(float(val))
                except (ValueError, TypeError):
                    pass
        return 0

    def generate(self, summary: SessionSummary, output_path: str,
                 candidate_name: str = "Candidate",
                 position: str = "Interview Session",
                 interview_data: dict = None,
                 combined_score: float = None):
        """Generate the complete multi-page PDF report.
        
        Pages:
            1: Executive Summary with combined overall score
            2: Detailed NVC Analysis (emotions, posture, gestures, timeline)
            3+: Q&A Analysis — every question, answer, accuracy score, feedback
        """

        os.makedirs(os.path.dirname(output_path) if os.path.dirname(output_path)
                     else ".", exist_ok=True)

        doc = SimpleDocTemplate(
            output_path, pagesize=A4,
            leftMargin=20*mm, rightMargin=20*mm,
            topMargin=15*mm, bottomMargin=15*mm)

        story = []

        # ── PAGE 1: Executive Summary ──
        story += self._build_page1(summary, candidate_name, position,
                                    interview_data=interview_data,
                                    combined_score=combined_score)
        story.append(PageBreak())

        # ── PAGE 2: Detailed NVC Analysis ──
        story += self._build_page2(summary, interview_data=interview_data)

        # ── PAGE 3+: Q&A Analysis (dynamic, can span multiple pages) ──
        if interview_data and interview_data.get("qa_analysis"):
            story.append(PageBreak())
            story += self._build_qa_pages(interview_data)

        doc.build(story)
        print(f"[PDF] Report generated: {output_path}")

    def _build_page1(self, s: SessionSummary, name: str, position: str,
                      interview_data: dict = None, combined_score: float = None) -> list:
        """Build Page 1: Executive Summary with combined overall score."""
        elements = []

        # Title
        elements.append(Paragraph("Interview Performance Report", self.styles['ReportTitle']))
        elements.append(Paragraph(
            f"{name} | {position} | {s.start_time}", self.styles['ReportSubtitle']))
        elements.append(HRFlowable(width="100%", color=C_PRIMARY, thickness=2))
        elements.append(Spacer(1, 8))

        # ── Combined Overall Score (prominently displayed) ──
        if combined_score is not None:
            score_color = C_SUCCESS if combined_score >= 70 else (
                C_WARNING if combined_score >= 40 else C_DANGER)
            elements.append(Paragraph("Overall Performance Score",
                                       self.styles['CombinedScoreTitle']))
            elements.append(Spacer(1, 8))
            elements.append(Paragraph(
                f'<font color="{score_color.hexval()}">{combined_score:.0f}%</font>',
                self.styles['CombinedScoreValue']))
            elements.append(Spacer(1, 8))
            # Sub-breakdown labels
            nvc_pct = min(100.0, s.overall_engagement_score)
            interview_pct = interview_data.get("overall_score", 0) if interview_data else 0
            breakdown_text = (
                f'<font size="9" color="{C_TEXT_GRAY.hexval()}">'
                f'Body Language: {nvc_pct:.0f}% &nbsp;&nbsp;|&nbsp;&nbsp; '
                f'Interview Q&amp;A: {interview_pct}%</font>'
            )
            elements.append(Paragraph(breakdown_text, self.styles['ReportSubtitle']))
            elements.append(Spacer(1, 12))

        # Session Info bar
        info_data = [[
            Paragraph(f"<b>Duration:</b> {s.duration_seconds:.0f}s", self.styles['RptSmallText']),
            Paragraph(f"<b>Frames:</b> {s.total_frames}", self.styles['RptSmallText']),
            Paragraph(f"<b>Date:</b> {s.start_time}", self.styles['RptSmallText']),
        ]]
        info_table = Table(info_data, colWidths=[170, 170, 170])
        info_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), C_BG_LIGHT),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('TOPPADDING', (0, 0), (-1, -1), 6),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
            ('BOX', (0, 0), (-1, -1), 0.5, C_TEXT_GRAY),
        ]))
        elements.append(info_table)
        elements.append(Spacer(1, 12))

        # Overall Scores
        elements.append(Paragraph("Overall Performance", self.styles['SectionHeader']))

        score_data = [[
            self._score_cell("Engagement", s.overall_engagement_score),
            self._score_cell("Confidence", s.overall_confidence_score),
            self._score_cell("Eye Contact", s.eye_contact_percentage),
            self._score_cell("Posture", s.avg_posture_score),
        ]]
        score_table = Table(score_data, colWidths=[127, 127, 127, 127])
        score_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('BOX', (0, 0), (-1, -1), 0.5, C_BG_LIGHT),
            ('INNERGRID', (0, 0), (-1, -1), 0.5, C_BG_LIGHT),
            ('TOPPADDING', (0, 0), (-1, -1), 14),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 14),
            ('MINROWHEIGHT', (0, 0), (-1, -1), 70),
        ]))
        elements.append(score_table)
        elements.append(Spacer(1, 12))

        # Radar Chart
        elements.append(Paragraph("Performance Radar", self.styles['SectionHeader']))
        radar_img = self._create_radar_chart(s)
        radar_flowable = RLImage(radar_img, width=420, height=340)
        radar_flowable.hAlign = 'CENTER'
        elements.append(radar_flowable)
        elements.append(Spacer(1, 16))

        # Key Metrics Grid
        elements.append(Paragraph("Key Metrics", self.styles['SectionHeader']))
        metrics_data = [[
            self._metric_cell("Dominant Emotion", s.dominant_emotion.upper()),
            self._metric_cell("Gestures/min", f"{s.gesture_frequency:.1f}"),
            self._metric_cell("Head Centered", f"{s.head_centered_percentage:.0f}%"),
            self._metric_cell("Fidgeting", f"{s.fidget_percentage:.0f}%"),
        ]]
        m_table = Table(metrics_data, colWidths=[127, 127, 127, 127])
        m_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('BOX', (0, 0), (-1, -1), 0.5, C_BG_LIGHT),
            ('INNERGRID', (0, 0), (-1, -1), 0.5, C_BG_LIGHT),
            ('TOPPADDING', (0, 0), (-1, -1), 14),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 14),
            ('MINROWHEIGHT', (0, 0), (-1, -1), 70),
        ]))
        elements.append(m_table)
        elements.append(Spacer(1, 12))

        # Strengths & Improvements
        strengths, improvements = self._analyze_strengths(s)
        col1 = self._bullet_list("Strengths", strengths, C_SUCCESS)
        col2 = self._bullet_list("Areas for Improvement", improvements, C_WARNING)
        si_table = Table([[col1, col2]], colWidths=[254, 254])
        si_table.setStyle(TableStyle([
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ]))
        elements.append(si_table)

        return elements

    def _build_page2(self, s: SessionSummary, interview_data: dict = None) -> list:
        """Build Page 2: Detailed Analysis."""
        elements = []

        elements.append(Paragraph("Detailed Analysis", self.styles['ReportTitle']))
        elements.append(HRFlowable(width="100%", color=C_PRIMARY, thickness=2))
        elements.append(Spacer(1, 8))

        # Emotion Distribution
        elements.append(Paragraph("Emotion Distribution", self.styles['SectionHeader']))
        if s.emotion_breakdown:
            pie_img = self._create_pie_chart(s.emotion_breakdown, "Emotions")
            elements.append(RLImage(pie_img, width=300, height=180))
        elements.append(Spacer(1, 8))

        # Posture Breakdown
        elements.append(Paragraph("Posture Analysis", self.styles['SectionHeader']))
        if s.posture_breakdown:
            bar_img = self._create_bar_chart(s.posture_breakdown, "Posture", "% of Time")
            elements.append(RLImage(bar_img, width=360, height=160))
        elements.append(Spacer(1, 8))

        # Eye Contact Timeline
        elements.append(Paragraph("Eye Contact Over Time", self.styles['SectionHeader']))
        if s.timeline:
            timeline_img = self._create_timeline_chart(s.timeline)
            elements.append(RLImage(timeline_img, width=420, height=150))
        elements.append(Spacer(1, 8))

        # Gesture Summary
        elements.append(Paragraph("Gesture Analysis", self.styles['SectionHeader']))
        if s.gesture_types:
            g_img = self._create_bar_chart(
                {k: v for k, v in s.gesture_types.items()},
                "Gesture Types", "Count")
            elements.append(RLImage(g_img, width=360, height=150))
        else:
            elements.append(Paragraph("No hand gestures detected during session.",
                                     self.styles['RptBodyText']))
        elements.append(Spacer(1, 10))

        # ── Voice Pitch & Sentiment Analysis ──
        if interview_data and interview_data.get("voice_analysis"):
            voice = interview_data["voice_analysis"]
            elements.append(Paragraph("Voice Pitch & Sentiment Analysis", self.styles['SectionHeader']))
            
            s_score = voice.get("sentiment_score", 0)
            sentiment_text = voice.get("sentiment", "Neutral")
            s_color = C_SUCCESS if s_score >= 70 else (C_WARNING if s_score >= 40 else C_DANGER)
            
            elements.append(Paragraph(
                f'<b>Overall Sentiment:</b> <font color="{s_color.hexval()}">{sentiment_text} ({s_score}%)</font>', 
                self.styles['RptBodyText']))
            elements.append(Paragraph(
                f'<b>Pitch & Tone Feedback:</b> {voice.get("pitch_tone_feedback", "N/A")}', 
                self.styles['RptBodyText']))
            elements.append(Spacer(1, 10))

        # Recommendations
        elements.append(Paragraph("Recommendations", self.styles['SectionHeader']))
        recs = self._generate_recommendations(s)
        for i, rec in enumerate(recs, 1):
            elements.append(Paragraph(f"<b>{i}.</b> {rec}", self.styles['RptBodyText']))

        return elements

    def _build_qa_pages(self, interview_data: dict) -> list:
        """Build Q&A Analysis pages — can span multiple pages dynamically."""
        elements = []

        elements.append(Paragraph("Question & Answer Analysis", self.styles['ReportTitle']))
        elements.append(HRFlowable(width="100%", color=C_PRIMARY, thickness=2))
        elements.append(Spacer(1, 8))

        qa_list = interview_data.get("qa_analysis", [])
        if not qa_list:
            elements.append(Paragraph(
                "No question-answer pairs were captured during this session.",
                self.styles['RptBodyText']))
            return elements

        # Summary bar
        avg_accuracy = sum(self._parse_qa_accuracy(q) for q in qa_list) / max(len(qa_list), 1)
        avg_color = C_SUCCESS if avg_accuracy >= 70 else (C_WARNING if avg_accuracy >= 40 else C_DANGER)
        summary_data = [[
            Paragraph(f'<b>Total Questions:</b> {len(qa_list)}', self.styles['RptSmallText']),
            Paragraph(
                f'<b>Average Accuracy:</b> <font color="{avg_color.hexval()}">{avg_accuracy:.0f}%</font>',
                self.styles['RptSmallText']),
            Paragraph(
                f'<b>Recommendation:</b> {interview_data.get("recommendation", "N/A")[:50]}',
                self.styles['RptSmallText']),
        ]]
        sum_table = Table(summary_data, colWidths=[160, 160, 160])
        sum_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), C_BG_LIGHT),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('TOPPADDING', (0, 0), (-1, -1), 6),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
            ('BOX', (0, 0), (-1, -1), 0.5, C_TEXT_GRAY),
        ]))
        elements.append(sum_table)
        elements.append(Spacer(1, 12))

        # Individual Q&A blocks
        for idx, qa in enumerate(qa_list, 1):
            block_elements = []
            
            question = qa.get("question", "N/A")
            answer = qa.get("answer", "No answer recorded")
            accuracy = self._parse_qa_accuracy(qa)
            feedback = qa.get("feedback", "")

            score_color = C_SUCCESS if accuracy >= 70 else (
                C_WARNING if accuracy >= 40 else C_DANGER)

            # Question header with score badge
            q_header = (
                f'<font color="{C_SECONDARY.hexval()}">Q{idx}.</font> {question}'
                f'&nbsp;&nbsp;&nbsp;'
                f'<font color="{score_color.hexval()}" size="12"><b>{accuracy}%</b></font>'
            )
            block_elements.append(Paragraph(q_header, self.styles['QAQuestion']))

            # Answer
            block_elements.append(Paragraph(
                f'<font color="{C_TEXT_GRAY.hexval()}"><b>Answer:</b></font> {answer}',
                self.styles['QAAnswer']))

            # Feedback
            if feedback:
                block_elements.append(Paragraph(
                    f'<font color="{C_TEXT_GRAY.hexval()}">💡</font> {feedback}',
                    self.styles['QAFeedback']))

            # Separator between Q&A blocks
            block_elements.append(HRFlowable(
                width="100%", color=C_BG_LIGHT, thickness=1))
            block_elements.append(Spacer(1, 4))
            
            # Wrap the entire Q&A block in KeepTogether to prevent bad page breaks
            elements.append(KeepTogether(block_elements))

        # Interview Strengths & Areas for Improvement
        strengths = interview_data.get("strengths", [])
        improvements = interview_data.get("areas_for_improvement", [])
        if strengths or improvements:
            elements.append(Spacer(1, 8))
            elements.append(Paragraph("Interview Assessment", self.styles['SectionHeader']))
            col1 = self._bullet_list("Strengths", strengths, C_SUCCESS) if strengths else []
            col2 = self._bullet_list("Areas for Improvement", improvements, C_WARNING) if improvements else []
            if col1 or col2:
                # 240 width to ensure it fits safely on the 480 points printable width
                si_table = Table([[col1 or "", col2 or ""]], colWidths=[240, 240])
                si_table.setStyle(TableStyle([
                    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                ]))
                # Keep table together
                elements.append(KeepTogether(si_table))

        # Detailed Feedback paragraph
        detailed = interview_data.get("detailed_feedback", "")
        if detailed:
            elements.append(Spacer(1, 8))
            elements.append(KeepTogether([
                Paragraph("Detailed Feedback", self.styles['SectionHeader']),
                Paragraph(detailed, self.styles['RptBodyText'])
            ]))

        return elements

    # ── Helper Methods ──

    def _score_cell(self, label: str, value: float):
        score_color = C_SUCCESS if value >= 70 else (
            C_WARNING if value >= 40 else C_DANGER)
        # Fix 1 & 8: Use a single Paragraph instead of KeepTogether to fix Table LayoutError (infinite height)
        content = (
            f'<font name="Helvetica-Bold" size="22" color="{score_color.hexval()}">{value:.0f}</font>'
            f'<br/><font size="4"> </font><br/>'
            f'<font size="11" color="{C_TEXT_GRAY.hexval()}">{label}</font>'
        )
        return Paragraph(content, ParagraphStyle('CellCombined', alignment=TA_CENTER))

    def _metric_cell(self, label: str, value: str):
        # Fix 2 & 8: Use a single Paragraph to prevent LayoutError
        content = (
            f'<font name="Helvetica-Bold" size="22" color="{C_PRIMARY.hexval()}">{value}</font>'
            f'<br/><font size="4"> </font><br/>'
            f'<font size="11" color="{C_TEXT_GRAY.hexval()}">{label}</font>'
        )
        return Paragraph(content, ParagraphStyle('CellCombined', alignment=TA_CENTER))

    def _bullet_list(self, title: str, items: list, color):
        parts = [Paragraph(f'<font color="{color.hexval()}"><b>{title}</b></font>',
                           self.styles['RptBodyText'])]
        for item in items:
            parts.append(Paragraph(f"  \u2022 {item}", self.styles['RptBodyText']))
        return parts

    def _create_radar_chart(self, s: SessionSummary) -> io.BytesIO:
        """Create a radar/spider chart for performance overview."""
        categories = config.RADAR_CATEGORIES
        values = [
            min(100, s.eye_contact_percentage),
            min(100, s.overall_confidence_score),
            min(100, s.avg_posture_score),
            min(100, s.gesture_frequency * 10),  # Scale gestures
            min(100, s.overall_engagement_score),
        ]
        N = len(categories)
        angles = [n / float(N) * 2 * math.pi for n in range(N)]
        values_plot = values + [values[0]]
        angles += [angles[0]]

        fig, ax = plt.subplots(1, 1, figsize=(5.5, 4.5), subplot_kw=dict(polar=True))
        ax.fill(angles, values_plot, color='#3366CC', alpha=0.25)
        ax.plot(angles, values_plot, color='#3366CC', linewidth=2)
        ax.scatter(angles[:-1], values, color='#3366CC', s=40, zorder=5)

        ax.set_xticks(angles[:-1])
        ax.set_xticklabels(categories, size=10)
        ax.tick_params(pad=16)
        ax.set_ylim(0, 100)
        ax.set_yticks([25, 50, 75, 100])
        ax.set_yticklabels(["25", "50", "75", "100"], size=6, color='gray')
        ax.grid(True, alpha=0.3)

        buf = io.BytesIO()
        fig.savefig(buf, format='png', dpi=120, bbox_inches='tight',
                   transparent=True)
        plt.close(fig)
        buf.seek(0)
        return buf

    def _create_pie_chart(self, data: dict, title: str) -> io.BytesIO:
        """Create a pie chart."""
        labels = list(data.keys())
        sizes = list(data.values())
        colors_list = ['#3366CC', '#2EBF62', '#F5A623', '#E6402E', '#9B59B6',
                       '#1ABC9C', '#E74C3C']

        fig, ax = plt.subplots(1, 1, figsize=(4.5, 2.5))
        wedges, texts, autotexts = ax.pie(
            sizes, labels=None, autopct='%1.0f%%',
            colors=colors_list[:len(labels)],
            startangle=90, pctdistance=0.8,
            textprops={'size': 8})
        ax.legend(labels, loc='center left', bbox_to_anchor=(1, 0.5),
                 fontsize=7, frameon=False)
        for t in autotexts:
            t.set_fontsize(7)

        buf = io.BytesIO()
        fig.savefig(buf, format='png', dpi=120, bbox_inches='tight')
        plt.close(fig)
        buf.seek(0)
        return buf

    def _create_bar_chart(self, data: dict, xlabel: str, ylabel: str) -> io.BytesIO:
        """Create a horizontal bar chart."""
        labels = list(data.keys())
        values = list(data.values())
        colors_list = ['#3366CC', '#2EBF62', '#F5A623', '#E6402E', '#9B59B6']

        fig, ax = plt.subplots(1, 1, figsize=(5, 2.2))
        bars = ax.barh(labels, values, color=colors_list[:len(labels)], height=0.5)
        ax.set_xlabel(ylabel, fontsize=8)
        ax.tick_params(axis='both', labelsize=7)
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        for bar, val in zip(bars, values):
            ax.text(bar.get_width() + 0.5, bar.get_y() + bar.get_height()/2,
                   f'{val:.1f}' if isinstance(val, float) else str(val),
                   va='center', fontsize=7)

        buf = io.BytesIO()
        fig.savefig(buf, format='png', dpi=120, bbox_inches='tight')
        plt.close(fig)
        buf.seek(0)
        return buf

    def _create_timeline_chart(self, timeline: list) -> io.BytesIO:
        """Create eye contact timeline chart."""
        times = [t["time"] for t in timeline]
        ec_scores = [t.get("eye_contact", 0) * 100 for t in timeline]
        posture_scores = [t.get("posture_score", 0) * 100 for t in timeline]

        fig, ax = plt.subplots(1, 1, figsize=(6, 2))
        ax.plot(times, ec_scores, color='#3366CC', linewidth=1.5,
               label='Eye Contact', alpha=0.8)
        ax.fill_between(times, ec_scores, alpha=0.1, color='#3366CC')
        ax.plot(times, posture_scores, color='#2EBF62', linewidth=1.5,
               label='Posture', alpha=0.8)
        ax.set_xlabel("Time (seconds)", fontsize=8)
        ax.set_ylabel("Score (%)", fontsize=8)
        ax.set_ylim(0, 105)
        ax.tick_params(axis='both', labelsize=7)
        ax.legend(fontsize=7, loc='lower right')
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.grid(True, alpha=0.2)

        buf = io.BytesIO()
        fig.savefig(buf, format='png', dpi=120, bbox_inches='tight')
        plt.close(fig)
        buf.seek(0)
        return buf

    def _analyze_strengths(self, s: SessionSummary):
        """Determine top strengths and improvement areas."""
        strengths = []
        improvements = []

        if s.eye_contact_percentage >= 60:
            strengths.append("Good eye contact maintained throughout session")
        else:
            improvements.append("Practice maintaining eye contact with the camera")

        if s.avg_posture_score >= 70:
            strengths.append("Upright and professional posture")
        else:
            improvements.append("Work on maintaining an upright posture")

        if s.overall_confidence_score >= 60:
            strengths.append("Projects confidence through body language")
        else:
            improvements.append("Build confidence through relaxed facial expressions")

        confident_pct = s.emotion_breakdown.get("confident", 0) + \
                       s.emotion_breakdown.get("engaged", 0)
        if confident_pct >= 40:
            strengths.append("Engaged and expressive facial expressions")
        else:
            improvements.append("Show more engagement through facial expressions")

        if s.fidget_percentage < 20:
            strengths.append("Minimal fidgeting — composed demeanor")
        else:
            improvements.append("Reduce hand fidgeting for a calmer presence")

        if s.head_centered_percentage >= 70:
            strengths.append("Stable head position — attentive appearance")
        else:
            improvements.append("Keep head centered and face the camera directly")

        if 3 <= s.gesture_frequency <= 15:
            strengths.append("Good use of hand gestures for emphasis")
        elif s.gesture_frequency < 3:
            improvements.append("Use more hand gestures to emphasize key points")
        else:
            improvements.append("Use fewer, more deliberate hand gestures")

        return strengths[:4], improvements[:4]

    def _generate_recommendations(self, s: SessionSummary) -> list:
        """Generate personalized improvement recommendations."""
        recs = []

        if s.eye_contact_percentage < 50:
            recs.append("Focus on looking directly at the camera lens during responses. "
                       "Place a sticky note near your camera as a reminder.")
        if s.avg_posture_score < 60:
            recs.append("Sit upright with shoulders back. Consider adjusting your chair "
                       "height so the camera is at eye level.")
        nervous_pct = s.emotion_breakdown.get("nervous", 0) + \
                     s.emotion_breakdown.get("stressed", 0)
        if nervous_pct > 30:
            recs.append("Practice deep breathing before interviews to reduce visible "
                       "nervousness. A calm face projects confidence.")
        if s.fidget_percentage > 25:
            recs.append("Keep hands resting on the desk or use purposeful gestures. "
                       "Avoid touching your face or playing with objects.")
        if s.gesture_frequency < 2:
            recs.append("Incorporate natural hand gestures when making key points. "
                       "This shows engagement and helps convey ideas clearly.")
        if s.head_centered_percentage < 60:
            recs.append("Maintain a stable head position facing the camera. "
                       "Avoid looking down at notes frequently.")

        if not recs:
            recs.append("Excellent performance! Continue practicing to maintain "
                       "these strong non-verbal communication skills.")

        return recs[:5]


# ════════════════════════════════════════════════════════════
# CLI TEST MODE
# ════════════════════════════════════════════════════════════

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--test", action="store_true", help="Generate test report")
    args = parser.parse_args()

    if args.test:
        # Create mock summary
        mock = SessionSummary(
            duration_seconds=120, total_frames=960,
            start_time="2026-05-06 10:00:00", end_time="2026-05-06 10:02:00",
            eye_contact_percentage=72.5, avg_eye_contact_score=0.68,
            dominant_emotion="confident",
            emotion_breakdown={"confident": 35.2, "engaged": 28.1,
                             "neutral": 22.4, "nervous": 10.1, "stressed": 4.2},
            avg_emotion_confidence=0.65,
            avg_posture_score=78.3,
            posture_breakdown={"upright": 72.0, "slouching": 18.0,
                             "leaning_left": 6.0, "leaning_right": 4.0},
            gesture_count=14, gesture_frequency=7.0,
            gesture_types={"open_palm": 6, "pointing": 4, "fist": 2, "peace_sign": 2},
            fidget_percentage=12.5,
            head_centered_percentage=81.3, avg_head_yaw=3.2, avg_head_pitch=2.1,
            overall_engagement_score=74.5, overall_confidence_score=71.2,
            timeline=[
                {"time": i, "eye_contact": 0.5 + 0.3 * np.sin(i/10),
                 "posture_score": 0.7 + 0.15 * np.cos(i/8),
                 "emotion": "confident", "emotion_confidence": 0.6}
                for i in range(120)
            ]
        )

        # Create mock interview Q&A data
        mock_interview_data = {
            "overall_score": 72,
            "voice_analysis": {
                "pitch_tone_feedback": "Voice pitch was stable and energetic. You maintained a confident tone throughout the session without significant drops in volume.",
                "sentiment": "Positive",
                "sentiment_score": 85
            },
            "qa_analysis": [
                {
                    "question": "Can you tell me about yourself and your background?",
                    "answer": "I am a software engineer with 3 years of experience in full-stack development. I have worked with React, Node.js, and Python extensively. I graduated from FAST-NUCES with a BS in Computer Science.",
                    "accuracy_score": 85,
                    "feedback": "Good introduction covering key areas. Could mention specific achievements or projects for stronger impact."
                },
                {
                    "question": "What is your experience with React and how have you used it in production?",
                    "answer": "I have used React for 2 years building e-commerce platforms and dashboards. I am familiar with hooks, context API, and Redux for state management.",
                    "accuracy_score": 78,
                    "feedback": "Solid technical knowledge demonstrated. Could provide more specific examples of production challenges solved."
                },
                {
                    "question": "How do you handle tight deadlines when working on multiple projects?",
                    "answer": "I prioritize tasks based on urgency and impact. I use Jira for tracking and communicate proactively with stakeholders if timelines are at risk.",
                    "accuracy_score": 70,
                    "feedback": "Good structured approach. Would benefit from a specific real-world example demonstrating this skill."
                },
                {
                    "question": "Can you explain the difference between REST and GraphQL APIs?",
                    "answer": "REST uses fixed endpoints while GraphQL has a single endpoint where clients can query exactly the data they need. GraphQL reduces over-fetching.",
                    "accuracy_score": 65,
                    "feedback": "Covers basics but misses important nuances like caching differences, error handling, and when to choose one over the other."
                },
                {
                    "question": "Describe a challenging bug you encountered and how you resolved it.",
                    "answer": "I had a memory leak in a Node.js application caused by unclosed database connections. I used heap snapshots to identify the issue and implemented connection pooling to fix it.",
                    "accuracy_score": 88,
                    "feedback": "Excellent answer with clear problem identification, debugging methodology, and solution implementation."
                },
            ],
            "scores": {
                "technical_accuracy": 75,
                "communication_clarity": 70,
                "confidence": 72,
                "problem_solving": 78,
                "cultural_fit": 68
            },
            "strengths": [
                "Strong technical foundation in full-stack development",
                "Clear communication style",
                "Good problem-solving approach with debugging"
            ],
            "areas_for_improvement": [
                "Provide more specific real-world examples",
                "Deepen knowledge of API design trade-offs",
                "Practice STAR method for behavioral questions"
            ],
            "detailed_feedback": "The candidate demonstrated solid technical skills across full-stack development. Their answers showed practical experience but could benefit from more depth in architectural discussions. Communication was clear and structured, though behavioral answers lacked specific examples using the STAR method.",
            "recommendation": "Consider — shows strong potential with room for growth"
        }

        # Combined score: 40% NVC + 60% Interview
        combined = round(74.5 * 0.4 + 72 * 0.6, 1)

        os.makedirs("reports", exist_ok=True)
        gen = ReportGenerator()
        gen.generate(mock, "reports/test_report.pdf",
                    candidate_name="Test Candidate",
                    position="Software Engineer",
                    interview_data=mock_interview_data,
                    combined_score=combined)
        print(f"Test report generated: reports/test_report.pdf (Combined: {combined}%)")

