# SEFM 2026 Submission - rocq-robot Tool Paper

## Submission Details

- **Conference**: SEFM 2026 (24th International Conference on Software Engineering and Formal Methods)
- **Location**: Malta
- **Date**: November 25-27, 2026 (Workshops: Nov 23-24)
- **Submission Type**: Tool Paper (8 pages + 1 page bibliography)

## Important Deadlines (AoE = UTC-12h)

- **Abstract submission**: June 16, 2026
- **Paper submission**: June 23, 2026
- **Author notification**: August 30, 2026
- **Camera ready**: September 14, 2026

## Submission Link

https://easychair.org/my/conference?conf=sefm2026

## Paper Details

- **Title**: rocq-robot: Enabling LLM-Driven Theorem Proving via Model Context Protocol
- **Author**: Gavin Mendel-Gleason (Scidonia, Dublin, Ireland)
- **File**: `rocq-robot-sefm2026.tex`
- **Format**: Springer LNCS (will need actual llncs.cls for final submission)
- **Current length**: 7 pages (within 8-page limit)

## Paper Structure

1. **Introduction** (1 page)
   - Neurosymbolic programming motivation
   - Key contributions (including cross-model validation)
   - Tool availability

2. **Tool Architecture** (1.5 pages)
   - System overview (MCP/LSP/Workspace layers)
   - 4 tool categories
   - Implementation details

3. **Usage Workflow** (1 page)
   - Installation and setup
   - Autonomous proof development workflow

4. **Case Study: Type Preservation Proof** (2 pages)
   - Problem specification
   - **Cross-model validation: Both DeepSeek v4 AND Claude Sonnet 4.5** (key result!)
   - Proof statistics with comparison (~850 tool calls, 21 cases, 7 lemmas)
   - Demonstrates robustness across different LLM architectures

5. **Related Work** (0.5 pages)
   - LLM theorem proving (Baldur, LeanDojo)
   - Proof assistant interfaces (coq-lsp, CoqPIE, Proof General)

6. **Lessons Learned and Future Directions** (0.5 pages)
   - Design insights
   - Future work

7. **Conclusion** (0.3 pages)

8. **Bibliography** (6 references)

## Key Strengths for SEFM

✅ **Perfect topic match**: "Software Engineering for AI models" and "Formal methods for AI safety"
✅ **Production-ready tool**: Open-source, npm-published, actively maintained
✅ **Cross-model validation**: BOTH DeepSeek v4 AND Claude Sonnet 4.5 independently completed the proof one-shot
✅ **Concrete demonstration**: Real proof (type preservation for PCF+references, 21 cases, 7 lemmas)
✅ **Robustness**: Works across different LLM architectures (open-source + proprietary)
✅ **Neurosymbolic AI**: Combines LLMs + formal verification
✅ **Industrial relevance**: Addresses SE + FM + AI integration

## To-Do Before Submission

### By June 16 (Abstract Deadline)

1. ✅ Draft paper completed
2. ⬜ Install proper LNCS class (`texlive-publishers` or manual download)
3. ⬜ Compile with actual LNCS format and verify 8-page limit
4. ⬜ Add video URL (if available)
5. ⬜ Add Zenodo DOI for tool artifact
6. ⬜ Submit abstract to EasyChair

### By June 23 (Full Paper Deadline)

7. ⬜ Final proofreading
8. ⬜ Verify all citations are correct
9. ⬜ Check LNCS formatting guidelines compliance
10. ⬜ Submit full paper PDF to EasyChair

## LNCS Installation (Required for Final Submission)

### Option 1: Install via package manager
```bash
sudo apt-get install texlive-publishers
```

### Option 2: Manual download from Springer
1. Visit: https://www.springer.com/gp/computer-science/lncs
2. Download "LaTeX2e Proceedings Templates (zip)"
3. Extract `llncs.cls` to paper directory

### Option 3: Use Overleaf
- Upload project to Overleaf (has LNCS built-in)

## Current Status

- ✅ Paper drafted (7 pages including bibliography)
- ✅ Compiled with article class (temporary)
- ✅ Within page limit (7/8 pages)
- ✅ Highlights cross-model validation (DeepSeek v4 + Claude Sonnet 4.5)
- ⬜ Needs LNCS class for final formatting
- ⬜ Needs abstract submission
- ⬜ Needs full paper submission

## Notes

- Current version uses `article` class as temporary substitute
- Final submission MUST use `\documentclass[runningheads]{llncs}`
- LNCS format may slightly change page count (typically ±0.5 pages)
- Keep bibliography to ~6 references (current count)
