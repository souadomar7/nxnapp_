import pandas as pd
import json

df = pd.read_csv("matrix_output.csv")
df = df.fillna("") # Replace NaNs with empty string

intents = []
for index, row in df.iterrows():
    # Helper to parse keywords
    kw_ar = [k.strip() for k in row["Keywords AR"].split("،")] if row["Keywords AR"] else []
    kw_en = [k.strip() for k in row["Keywords EN"].split(",")] if row["Keywords EN"] else []
    
    intent = {
        "id": row["ID"],
        "categoryAr": row["Category AR"],
        "categoryEn": row["Category EN"],
        "intentAr": row["Intent AR"],
        "intentEn": row["Intent EN"],
        "questionAr": row["Question AR"],
        "questionEn": row["Question EN"],
        "answerAr": row["Answer AR"],
        "answerEn": row["Answer EN"],
        "keywordsAr": kw_ar,
        "keywordsEn": kw_en,
        "requiredDataAr": row["Required Data AR"],
        "requiredDataEn": row["Required Data EN"],
        "botActionAr": row["Bot Action AR"],
        "botActionEn": row["Bot Action EN"],
        "escalate": True if row["Escalate?"] == "Yes" else False,
        "escalationReasonAr": row["Escalation Reason AR"],
        "escalationReasonEn": row["Escalation Reason EN"],
        "priority": row["Priority"]
    }
    intents.append(intent)

with open("assets/data/chatbot_matrix.json", "w", encoding="utf-8") as f:
    json.dump(intents, f, ensure_ascii=False, indent=2)

print("Created assets/data/chatbot_matrix.json successfully.")
