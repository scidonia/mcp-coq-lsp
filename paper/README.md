# ECOOP 2026 Demo Paper

This directory contains the demo paper submission for **rocq-robot** to ECOOP 2026.

## Files

- `abstract-step1.tex` - 1-page abstract for Step 1 submission (due April 10, 2026)
- `rocq-robot-demo.tex` - Full 4-6 page demo paper for Step 2 submission (due May 31, 2026)

## Submission Process

ECOOP 2026 uses a two-step process:

### Step 1: Abstract Submission
- **Deadline**: April 10, 2026 (AoE)
- **Length**: 1 page
- **Notification**: May 13, 2026
- **Purpose**: Get invited to demonstrate the tool

### Step 2: Demo Paper Submission (Optional)
- **Deadline**: May 31, 2026 (AoE)
- **Length**: 4-6 pages (including references)
- **Notification**: June 15, 2026
- **Publication**: ACM DL ECOOP Companion Proceedings

## Building

**Note**: The ACM acmart class requires additional fonts (libertine, inconsolata, newtxmath). If you encounter font expansion errors, you may need to install these packages or use an updated TeX distribution.

```bash
# Build abstract (Step 1)
pdflatex abstract-step1.tex
bibtex abstract-step1
pdflatex abstract-step1.tex
pdflatex abstract-step1.tex

# Build full paper (Step 2)
# Note: Requires acmart.cls - run `latex acmart.ins` first if needed
pdflatex rocq-robot-demo.tex
bibtex rocq-robot-demo
pdflatex rocq-robot-demo.tex
pdflatex rocq-robot-demo.tex

# Simplified version (for testing)
pdflatex rocq-robot-demo-simple.tex
```

## Submission Link

https://ecoop2026demo.hotcrp.com/

## Conference Details

- **Conference**: ECOOP 2026
- **Location**: Brussels, Belgium
- **Dates**: June 29 - July 3, 2026
- **Venue**: Vrije Universiteit Brussel
- **Website**: https://2026.ecoop.org/track/ecoop-2026-demo
