from textstat import flesch_kincaid_grade

def analyze_and_classify_vocabulary_difficulty(text):
    try:
        # Calculate Flesch-Kincaid Grade Level
        grade_level = flesch_kincaid_grade(text)

        
        # Classify vocabulary difficulty
        if grade_level <= 5:
            difficulty_class = "Very Easy"
        elif 6 <= grade_level <= 8:
            difficulty_class = "Easy"
        elif 9 <= grade_level <= 12:
            difficulty_class = "Moderate"
        elif 13 <= grade_level <= 16:
            difficulty_class = "Difficult"
        else:
            difficulty_class = "Very Difficult"

        return grade_level, difficulty_class

    except Exception as e:
        print(f"Error: {e}")
        return None, None


