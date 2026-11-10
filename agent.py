import os, re, subprocess, sys, time
from google import genai
client = genai.Client(api_key=os.environ["API_KEY"])

def ask_llm(prompt):
    for i in range(5):
        try:
            r = client.models.generate_content(model="gemini-flash-lite-latest", contents=prompt)
            return r.text
        except Exception as e:
            print(f"API error ({e.__class__.__name__}), retrying in {10*(i+1)}s...")
            time.sleep(10 * (i + 1))
    raise RuntimeError("API kept failing, try again later")

def clean(code):
    m = re.search(r"```(?:verilog|systemverilog)?\n(.*?)```", code, re.S)
    return m.group(1) if m else code

def simulate(dut, tb):
    c = subprocess.run(["iverilog", "-o", "sim.out", dut, tb],
                       capture_output=True, text=True, timeout=30)
    if c.returncode != 0:
        return False, "COMPILE ERROR:\n" + c.stderr
    r = subprocess.run(["vvp", "sim.out"], capture_output=True, text=True, timeout=30)
    out = r.stdout + r.stderr
    return ("PASS" in out and "FAIL" not in out), out

name = sys.argv[1]
dut = f"{name}.v"
spec = open(f"{name}_spec.txt").read()
rtl = open(dut).read()

header = re.search(r"module.*?\);", rtl, re.S).group(0)

base = (f"Write a self-checking Verilog testbench named tb for this module.\n"
        f"Spec:\n{spec}\n"
        f"Module header:\n{header}\n"
        "Rules: compare outputs against expected values computed from the spec, "
        "use at least 6 test vectors per behavior including corner cases, "
        "print FAIL with details on any mismatch, print PASS only if all checks pass, "
        "end with $finish. Output only code.")
prompt = base
sim_fails = 0

for attempt in range(1, 6):
    tb = clean(ask_llm(prompt))
    open("tb.v", "w").write(tb)
    try:
        ok, log = simulate(dut, "tb.v")
    except subprocess.TimeoutExpired:
        ok, log = False, "COMPILE ERROR: simulation timed out (missing $finish?)"
    print(f"Attempt {attempt}: {'PASS' if ok else 'FAIL'}")
    if ok:
        break
    if log.startswith("COMPILE ERROR"):
        prompt = base + f"\n\nYour last testbench had this error:\n{log}\nFix it. Output only code."
    else:
        sim_fails += 1
        prompt = base          # fresh testbench, no feedback from the failure
        print(log[:400])
else:
    if sim_fails >= 3:
        print("DUT likely has a bug: independent testbenches keep failing.")
for attempt in range(1, 6):
    tb = clean(ask_llm(prompt))
    open("tb.v", "w").write(tb)
    ok, log = simulate(dut, "tb.v")
    print(f"Attempt {attempt}: {'PASS' if ok else 'FAIL'}")
    if ok:
        break
    prompt += f"\n\nYour last testbench failed:\n{log}\nFix it. Output only code."
