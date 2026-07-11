import pandas as pd
import sys

file_path = "/Users/suadsayed/Downloads/khazen_w_wasel_chatbot_QA_bilingual (1) (1).xlsx"
try:
    df = pd.read_excel(file_path)
    df.to_csv("matrix_output.csv", index=False)
    print("Successfully converted to matrix_output.csv")
    print(df.head(10).to_string())
except Exception as e:
    print(f"Error: {e}")
