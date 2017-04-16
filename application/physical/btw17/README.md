# Usage #

```bash
pip install -r requirements
adapt path to sqlite3 db
have redis and prometheus running
python3.5 getfeeds.py
python3.5 enqueue_jobs.py
rq worker default
rq-dashboard
```
