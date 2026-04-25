# docs/

Long-form documentation that doesn't fit at repo root.

---

## Layout

```
docs/
├── README.md            # this file
├── adr/                 # Architecture Decision Records (Michael Nygard format)
│   └── NNNN-title.md
├── design/              # design docs, mockups, UX notes
└── images/              # diagrams, screenshots used by other docs
```

---

## Architecture Decision Records (ADRs)

Use `docs/adr/NNNN-title.md` for non-trivial architectural choices. Format:

```markdown
# NNNN. Title

Date: YYYY-MM-DD

## Status
Proposed | Accepted | Deprecated | Superseded by ADR-XXXX

## Context
What is the issue we're addressing?

## Decision
What did we decide?

## Consequences
What are the trade-offs and follow-ups?
```

Reference: [Michael Nygard ADR template](https://github.com/joelparkerhenderson/architecture-decision-record/blob/main/locales/en/templates/decision-record-template-by-michael-nygard/index.md).
