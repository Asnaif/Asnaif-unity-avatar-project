from langchain_community.document_loaders import PyPDFLoader


def textExtractionPDF(path):
    loader = PyPDFLoader(path)
    pages = loader.load_and_split()
    # Saare pages ka text combine karo (max 50 pages limit)
    max_pages = 50
    pages_to_extract = pages[:max_pages] if len(pages) > max_pages else pages
    extractedText = "\n".join([page.page_content for page in pages_to_extract])
    
    # Debug log to confirm all pages are being used
    print(f"📄 Extracted text from {len(pages_to_extract)} pages (Total pages in PDF: {len(pages)})")
    print(f"📝 Total extracted text length: {len(extractedText)} characters")
    
    return extractedText