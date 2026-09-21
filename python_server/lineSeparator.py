# from langchain_openai import OpenAI
# from langchain_core.prompts import PromptTemplate
# from key import OpenApikey


# def lineSeparator(extractedText):

#     templateQA = """I am making an app where user can record audio and get back the extracted text from the audio. I have extracted text from the audio and providing it as content below. There is one problem with the extracted text that its not catering sentence structure. Now you need to add punctuations according to the context of the content and return only the puntuated text as answer. (ignore any abnormal data as I have extracted data from the audio file so there can be some data which doesnt make any sense. So just focus on the completing sentences with periods."

#     Content: {query}

#     Answer: """

#     # create a prompt template for QA
#     promptTemplateLineSep = PromptTemplate(
#         input_variables=["query"],
#         template=templateQA
#     )

#     contentLineSep = extractedText

#     formattedTemplateLineSep = promptTemplateLineSep.format(
#             query=contentLineSep
#         )

#     # initialize the models
#     openai = OpenAI(
#         model_name="gpt-3.5-turbo-instruct",
#         openai_api_key= OpenApikey,
#         temperature=0.5
#     )

    
#     response = openai.chat.completions.create(
#     model="gpt-3.5-turbo",
#     messages=[
#         {"role": "system", "content": "You are a helpful assistant that adds punctuation to text."},
#         {"role": "user", "content": formattedTemplateLineSep}
#     ]
# )
#     return response.choices[0].message.content

from openai import OpenAI
from key import OpenApikey


def lineSeparator(extractedText):
    
    # Initialize OpenAI client
    client = OpenAI(api_key=OpenApikey)
    
    prompt = f"""I am making an app where user can record audio and get back the extracted text from the audio. I have extracted text from the audio and providing it as content below. There is one problem with the extracted text that its not catering sentence structure. Now you need to add punctuations according to the context of the content and return only the punctuated text as answer. (ignore any abnormal data as I have extracted data from the audio file so there can be some data which doesn't make any sense. So just focus on completing sentences with periods.)

Content: {extractedText}

Answer:"""
    
    # Call OpenAI API
    response = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[
            {"role": "system", "content": "You are a helpful assistant that adds punctuation to text."},
            {"role": "user", "content": prompt}
        ],
        temperature=0.5
    )
    
    return response.choices[0].message.content