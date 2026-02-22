# Practice Lab 03: Directional Fee Design (Mechanism + Hook Mapping)

**Goal**: Turn Nezlobin's directional fee idea into a testable hook spec.

---

## Step 1: Define Direction Conventions

Write down and test your conventions for:
- `zeroForOne`
- token0 price up/down
- continuation vs reversal flow

If this step is wrong, the whole fee mechanism will be backwards.

---

## Step 2: Define Per-Pool State

List the minimum state required:
- last block seen
- last tick
- last delta
- base fee
- bounded fee outputs

Then decide:
- what is immutable
- what is configurable
- what is derived on each swap

---

## Step 3: Fee Formula (Version 1)

Choose one:
- linear
- capped linear
- stepwise buckets

Document:
- min fee
- max fee
- adjustment coefficient
- safety clamps

---

## Step 4: Test Cases Before Coding

Write at least 10 tests on paper/markdown before implementing.

Must include:
- same-block multiple swaps
- zero delta block
- positive delta
- negative delta
- min/max cap hit
- flag bit set on override fee

---

## Step 5: Adversarial Thinking

Answer:
- how might an arbitrageur game the fee?
- can a user force noisy fee changes cheaply?
- what metrics would prove the hook is helping LPs?

