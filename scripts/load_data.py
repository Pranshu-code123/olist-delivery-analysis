import glob, os
import pandas as pd
from urllib.parse import quote_plus
from sqlalchemy import create_engine, types

password = quote_plus(os.environ["MYSQL_PASSWORD"])
engine = create_engine(f"mysql+pymysql://root:{password}@localhost:3306/olist")

for f in glob.glob("data/*.csv"):
    name = (os.path.basename(f)
            .replace("olist_", "")
            .replace("_dataset.csv", "")
            .replace(".csv", ""))
    df = pd.read_csv(f)

    dtypes = {}
    for col in df.columns:
        if "date" in col or "timestamp" in col or col.endswith("_at"):
            df[col] = pd.to_datetime(df[col])
            dtypes[col] = types.DATETIME()
        elif pd.api.types.is_string_dtype(df[col]):
            dtypes[col] = types.TEXT() if col.startswith("review_comment") else types.VARCHAR(255)

    df.to_sql(name, engine, if_exists="replace", index=False, dtype=dtypes, chunksize=5000)
    print(name, len(df))