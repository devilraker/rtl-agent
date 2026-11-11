# RTL Testbench Agent

Python agent that turns a plain-English spec into a self-checking Verilog testbench using an LLM (Gemini), then simulates it with Icarus Verilog.

## Usage
1. Put `<name>.v` (design) and `<name>_spec.txt` (spec) in the folder.
2. `export API_KEY=your_key`
3. `python agent.py <name>`

## How it works
- Sends the spec and module header to the LLM and saves the testbench as `tb.v`.
- Compiles and simulates with Icarus Verilog; PASS only if no FAIL is printed.
- Retries up to 5 times. The agent never edits the design.

## Results
| Module | Result | Attempts | Injected bugs caught |
|---|---|---|---|
| counter | PASS | 1 | 1/1 |
| alu | PASS | 1-2 | 4/4 |

## Findings
- Generated testbenches vary between runs, and one failed on a correct design before a retry passed.
- Coverage is thin on some operations (about 4 cases each).
