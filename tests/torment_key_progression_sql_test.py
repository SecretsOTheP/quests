"""Offline guard/weight tests; SQLite adaptation, no server DB connection.

Run: python3 tests/torment_key_progression_sql_test.py [quest-root]
"""
import re
import sqlite3
import sys
from pathlib import Path

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
source = (root / "sql/2026_10_15_Torment_Key_Progression.sql").read_text()
# Independent fixture expectations, including placeholder rebalancing.
weights = [
    (225595, 207313, 15, 45), (225595, 207009, 42, 27), (225595, 207282, 43, 28),
    (225594, 207314, 15, 45), (225594, 207288, 42, 27), (225594, 207043, 43, 28),
    (207041, 207315, 15, 45), (207041, 207041, 42, 27), (207041, 207286, 43, 28),
    (225596, 207316, 15, 45), (225596, 207218, 22, 14),
    (225596, 207290, 23, 15), (225596, 207294, 40, 26),
]

def test_guard(sql):
    return sql.replace("WHERE id = 346955", "WHERE DATABASE() = 'eqmac'\n  AND id = 346955").replace(
        "WHERE se.spawngroupID IN (225595, 225594, 207041, 225596);",
        "WHERE se.spawngroupID IN (225595, 225594, 207041, 225596)\n  AND DATABASE() = 'eqmac';")

def sqlite_sql(sql):
    sql = sql.replace(" FORCE INDEX (PRIMARY)", "")
    # Adapt only UPDATE JOIN to SQLite UPDATE FROM. The eligibility aggregate,
    # CASE assignments, WHERE guards and standalone verification stay intact.
    pattern = (r"UPDATE spawnentry AS se\s+JOIN \(\n(.*?)\n\) AS eligible "
               r"ON eligible.group_id = se.spawngroupID\s+SET se.chance = (.*?)\s+WHERE (.*?);")
    def rewrite(match):
        return ("UPDATE spawnentry AS se SET chance = " + match.group(2)
                + " FROM (\n" + match.group(1) + "\n) AS eligible "
                + "WHERE eligible.group_id = se.spawngroupID AND " + match.group(3) + ";")
    sql, count = re.subn(pattern, rewrite, sql, flags=re.S)
    assert count == 1
    return sql

def statements(sql):
    return [s.strip() for s in re.sub(r"--[^\n]*", "", sql).split(";") if s.strip()]

def fixture(realm="eqmac"):
    db = sqlite3.connect(":memory:")
    db.create_function("DATABASE", 0, lambda: realm)
    db.executescript("""
        CREATE TABLE spawn2 (id INTEGER PRIMARY KEY, zone TEXT,
            raid_target_spawnpoint INTEGER, spawngroupID INTEGER, respawntime INTEGER);
        CREATE TABLE spawnentry (spawngroupID INTEGER, npcID INTEGER, chance INTEGER,
            PRIMARY KEY (spawngroupID, npcID));
        CREATE TABLE npc_types (id INTEGER PRIMARY KEY, name TEXT);
        INSERT INTO spawn2 VALUES (346955,'potorment',0,9000,86400);
        INSERT INTO spawn2 VALUES (346828,'potorment',0,9001,1800);
        INSERT INTO spawnentry VALUES (9000,207028,100),(9001,207031,100),(9999,123,100);
    """)
    db.executemany("INSERT INTO spawnentry VALUES (?,?,?)", [(g, n, old) for g, n, old, new in weights])
    db.executemany("INSERT INTO npc_types VALUES (?,?)", [(n, str(n)) for n in {r[1] for r in weights}])
    return db

def group(db, group_id):
    return db.execute("SELECT npcID,chance FROM spawnentry WHERE spawngroupID=? ORDER BY npcID", (group_id,)).fetchall()

def run(db, guarded=False):
    db.executescript(sqlite_sql(test_guard(source) if guarded else source))

checks = 0
def check(ok, message):
    global checks
    assert ok, message
    checks += 1

groups = sorted({r[0] for r in weights})
db = fixture()
run(db)
for g in groups:
    check(group(db, g) == sorted((n, new) for gid, n, old, new in weights if gid == g), "All intended weights applied")
    check(sum(chance for n, chance in group(db, g)) == 100, "Group totals 100")
for n in (207313, 207314, 207315, 207316):
    check(db.execute("SELECT chance FROM spawnentry WHERE npcID=?", (n,)).fetchone()[0] == 45, "Avatar chance is 45")
check(db.execute("SELECT respawntime FROM spawn2 WHERE id=346955").fetchone()[0] == 1800, "Entry timer aligned")
check(db.execute("SELECT respawntime FROM spawn2 WHERE id=346828").fetchone()[0] == 1800, "Horror timer preserved")
check(group(db, 9999) == [(123, 100)], "Unrelated group preserved")
before = db.execute("SELECT * FROM spawnentry ORDER BY spawngroupID,npcID").fetchall()
run(db)
check(db.execute("SELECT * FROM spawnentry ORDER BY spawngroupID,npcID").fetchall() == before, "Rerun is idempotent")

for change in [
    "UPDATE spawnentry SET chance=17 WHERE npcID=207313",
    "DELETE FROM spawnentry WHERE npcID=207009",
    "INSERT INTO spawnentry VALUES (225595,999,1)",
    "DELETE FROM spawnentry WHERE spawngroupID=225595",
]:
    db = fixture(); db.execute(change); before = group(db, 225595)
    run(db)
    check(group(db, 225595) == before, "Unexpected group is skipped as a whole")
    check(dict(group(db, 225594))[207314] == 45, "Independent valid group still updates")

db = fixture(); db.execute("UPDATE spawnentry SET chance=45 WHERE npcID=207313")
run(db)
check(sum(c for n, c in group(db, 225595)) == 100, "Known partially applied group is completed")

for realm in ("eqmac", "pq"):
    db = fixture(realm); run(db, guarded=True)
    check(db.execute("SELECT respawntime FROM spawn2 WHERE id=346955").fetchone()[0] == (1800 if realm == "eqmac" else 86400), "TEST guard protects entry timer")
    check(dict(group(db, 225595))[207313] == (45 if realm == "eqmac" else 15), "TEST guard protects avatar weights")

# Regression: a selected UPDATE or SELECT works on a fresh connection with
# only the game tables. No preceding CREATE/INSERT or session state is needed.
parts = statements(sqlite_sql(test_guard(source)))
check(len(parts) == 5, "Two updates and three standalone reads")
for statement in parts:
    db = fixture()
    rows = db.execute(statement).fetchall()
    if statement.startswith("UPDATE spawnentry"):
        check(dict(group(db, 225595))[207313] == 45, "Selected avatar update works alone")
    elif statement.startswith("SELECT"):
        check(bool(rows), "Selected verification works alone")

# Standalone verification exposes missing/extra/invalid groups, not just rows
# still present, and distinguishes valid old values from applied values.
verification = parts[2]
db = fixture()
rows = db.execute(verification).fetchall()
check(len(rows) == 13 and all(row[-1] == "DIFF" for row in rows), "Old weights are DIFF")
run(db)
rows = db.execute(verification).fetchall()
check(len(rows) == 13 and all(row[-1] == "MATCH" for row in rows), "Applied weights are MATCH")
for change in [
    "UPDATE spawnentry SET chance=17 WHERE npcID=207313",
    "DELETE FROM spawnentry WHERE npcID=207009",
    "INSERT INTO spawnentry VALUES (225595,999,1)",
    "DELETE FROM spawnentry WHERE spawngroupID=225595",
]:
    db = fixture(); db.execute(change)
    rows = [r for r in db.execute(verification).fetchall() if r[1] == 225595]
    check(len(rows) == 3 and all(r[-1] == "SKIPPED GROUP: REVIEW" for r in rows), "Invalid group reported in full")

# Timer guards still protect unrelated/unexpected spawn definitions.
for change in [
    "UPDATE spawn2 SET zone='other' WHERE id=346955",
    "UPDATE spawn2 SET raid_target_spawnpoint=1 WHERE id=346955",
    "UPDATE spawn2 SET respawntime=7200 WHERE id=346955",
    "UPDATE spawnentry SET npcID=999 WHERE spawngroupID=9000",
]:
    db = fixture(); db.execute(change)
    before = db.execute("SELECT * FROM spawn2 WHERE id=346955").fetchone()
    run(db)
    check(db.execute("SELECT * FROM spawn2 WHERE id=346955").fetchone() == before, "Unexpected timer definition preserved")

# If supplied, validate the exact exported TEST file too.
if len(sys.argv) > 2:
    exported = Path(sys.argv[2]).read_text()
    check(statements(exported) == statements(test_guard(source)), "TEST export matches guarded migration")
    for realm in ("eqmac", "pq"):
        db = fixture(realm)
        before = db.execute("SELECT * FROM spawnentry ORDER BY spawngroupID,npcID").fetchall()
        db.executescript(sqlite_sql(exported))
        if realm == "pq":
            check(db.execute("SELECT * FROM spawnentry ORDER BY spawngroupID,npcID").fetchall() == before, "Actual export preserves every LIVE weight")
            check(db.execute("SELECT respawntime FROM spawn2 WHERE id=346955").fetchone()[0] == 86400, "Actual export preserves LIVE timer")
        else:
            check(all(dict(group(db, g))[n] == new for g,n,old,new in weights), "Actual TEST export applies all weights")

print(f"{checks} offline Torment SQL checks passed (SQLite adaptation, no server database).")
