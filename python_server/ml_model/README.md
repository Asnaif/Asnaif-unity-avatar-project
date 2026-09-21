# ChaLearn First Impressions V2 - Dataset Setup

## Download Instructions

1. Go to: http://chalearnlap.cvc.uab.cat/dataset/24/description/
2. Register/Login to ChaLearn LAP
3. Download ALL 3 splits:
   - **Training** — videos (.mp4) + annotation (.pkl) + transcription (.pkl)
   - **Validation** — videos (.mp4) + annotation (.pkl) + transcription (.pkl)
   - **Test** — videos (.mp4) + annotation (.pkl) + transcription (.pkl)

## Expected Folder Structure

Extract all zip files and arrange like this:

```
ml_model/
├── dataset/
│   ├── annotation/
│   │   ├── annotation_training.pkl
│   │   ├── annotation_validation.pkl
│   │   └── annotation_test.pkl
│   ├── videos/
│   │   ├── (all .mp4 clips from train, validation, AND test)
│   │   ├── video1.mp4
│   │   ├── video2.mp4
│   │   └── ...
│   └── transcription/
│       ├── transcription_training.pkl
│       ├── transcription_validation.pkl
│       └── transcription_test.pkl
├── train_communication_model.py
├── output/                          (auto-created after training)
│   ├── communication_model.pkl
│   ├── communication_scaler.pkl
│   ├── chalearn_features.csv
│   ├── feature_importance.png
│   └── model_metadata.pkl
└── README.md (this file)
```

## Google Colab Training

1. Upload `train_communication_model.py` and dataset to Colab
2. Run: `!pip install librosa scikit-learn joblib textstat transformers soundfile moviepy`
3. Run the script
4. Download `communication_model.pkl` and `communication_scaler.pkl` from output/
5. Place them in this `ml_model/` folder

## After Training

The Flask server will automatically detect and load the model files on startup.
