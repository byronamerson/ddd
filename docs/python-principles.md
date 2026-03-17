# Python Development Principles

*The authoritative reference for how Python code is written in this project.
Read this before writing any function. These principles take precedence
over cleverness, brevity, or convention.*

---

## 0. The One Rule

> *Decompose a big problem into smaller pieces, then solve each piece
> with a function or combination of functions.*

Everything else is a consequence of applying this in Python.

---

## 1. Read the Docs — Every Time

Before writing a function that uses a package, read that package's
documentation. Do not rely on training data or memory.

```python
help(pd.DataFrame.assign)   # not df["col"] = ...
help(pd.DataFrame.pipe)     # not nested function calls
help(pathlib.Path)          # not os.path.join
```

---

## 2. Pure Functions, I/O at the Boundary

- All inputs are explicit arguments. No free variables, no global state.
- `.assign()` over in-place mutation. Never `inplace=True`.
- File reading and writing happen once, in the outermost orchestrator.

```python
# ✅ Pure — all inputs explicit
def clean_discharge(df):
    return df.assign(
        discharge_cms=lambda d: d["discharge_cfs"] * 0.028317
    ).drop(columns=["discharge_cfs"])
```

---

## 3. One Function, One Job

If the name needs "and", split it. If it needs a long comment
explaining its phases, split it.

---

## 4. Naming

| Pattern | Example |
|---------|---------|
| `verb_noun` | `locate_headers`, `parse_timestamp` |
| `is_*` / `has_*` | `is_sentinel`, `has_time_blocks` |
| `_private` | `_parse_block` (internal helper, underscore prefix) |

Internal helpers use a leading underscore. Only functions intended
for import by users omit it.

---

## 5. Method Chains and `.pipe()`

```python
result = (
    raw_df
    .pipe(remove_outliers, col="discharge_cms")
    .pipe(add_water_year)
    .assign(log_q=lambda d: np.log10(d["discharge_cms"].clip(lower=1e-6)))
)
```

Use `.pipe()` to insert named functions into chains. Use `.assign()`
for column creation. Wrap long chains in parentheses.

---

## 6. No Deep Nesting

Max one level of comprehension for short, obvious transforms.
Name anything multi-line or with an `if/else` expression.

---

## 7. Docstrings Describe the Domain

```python
def compute_mannings_velocity(n, r_h, s):
    """Compute cross-sectional average velocity via Manning's equation.

    Parameters
    ----------
    n : float
        Manning's roughness coefficient (dimensionless). Typical range
        0.02 (smooth concrete) to 0.07 (dense floodplain vegetation).
    r_h : float
        Hydraulic radius (m). Cross-sectional area / wetted perimeter.
    s : float
        Energy slope (m/m). Approximated as bed slope for uniform flow.

    Returns
    -------
    float
        Cross-sectional average velocity (m/s).

    References
    ----------
    Chow, V.T. (1959). Open-Channel Hydraulics, McGraw-Hill, Eq. 5-10.
    """
    return (1.0 / n) * r_h ** (2.0 / 3.0) * s ** 0.5
```

---

## 8. Validate at the Boundary

```python
def read_data(path, var_names=("pressure", "temperature")):
    path = Path(path)
    if not path.exists():
        raise FileNotFoundError(f"Data file not found: {path}")
    if not isinstance(var_names, (list, tuple)) or len(var_names) < 1:
        raise ValueError("var_names must be a non-empty list or tuple")
    # internal helpers below this point trust their inputs
```

---

## 9. Testing with pytest

- Test helpers directly, not through the orchestrator.
- Use `pytest.approx` for floats.
- Use fixtures in `conftest.py` for shared test data.
- Test observable behaviour, not implementation details.

```python
def test_mannings_velocity():
    result = compute_mannings_velocity(0.035, 1.5, 0.001)
    assert result == pytest.approx(1.18, rel=0.01)
```

---

## 10. Tooling

- **Ruff** for linting and formatting (replaces Black, flake8, isort).
- **Type hints** on public function signatures.
- Configure in `pyproject.toml`.

---

## Quick Reference

| Principle | In practice |
|-----------|-------------|
| Pure functions | All inputs explicit; no free variables |
| No in-place mutation | `.assign()` and `.drop()` return new DataFrames |
| I/O at boundary | `Path(p).read_text()` once in the orchestrator |
| One job per function | If you need "and" in the name, split it |
| `_underscore` for internal | No underscore on public API |
| `.pipe()` for named steps | Insert functions into chains |
| Validate once | At the top of the public function |
| Test helpers directly | Don't route all tests through the orchestrator |
| `pytest.approx` for floats | Never assert exact float equality |
| Ruff for formatting | One tool, `pyproject.toml` |
