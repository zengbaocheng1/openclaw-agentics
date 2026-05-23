#!/usr/bin/env python3
"""
knowledge-learner helper: save a knowledge entry to memory/knowledge/
Usage: python3 scripts/save_knowledge.py <title> <source> <tags> <content_file>
"""

import sys
import os
from datetime import datetime


def slugify(text: str) -> str:
    """Convert text to a filename-safe slug."""
    slug = text.lower().strip()
    slug = ''.join(c if c.isalnum() or c in '-_' else '-' for c in slug)
    slug = '-'.join(slug.split('-')[:6])  # max 6 segments
    return slug or 'untitled'


def main():
    if len(sys.argv) < 5:
        print("Usage: save_knowledge.py <title> <source> <tags> <content_file>", file=sys.stderr)
        sys.exit(1)

    title = sys.argv[1]
    source = sys.argv[2]
    tags = sys.argv[3]
    content_file = sys.argv[4]

    if not os.path.exists(content_file):
        print(f"Error: content file '{content_file}' not found", file=sys.stderr)
        sys.exit(1)

    with open(content_file, 'r') as f:
        body = f.read()

    date_str = datetime.now().strftime('%Y-%m-%d')
    slug = slugify(title)
    filename = f"{date_str}_{slug}.md"

    # Ensure output directory exists
    workspace = os.environ.get('OPENCLAW_WORKSPACE', os.path.expanduser('~/.openclaw/workspace'))
    out_dir = os.path.join(workspace, 'memory', 'knowledge')
    os.makedirs(out_dir, exist_ok=True)

    out_path = os.path.join(out_dir, filename)

    template = f"""# {title}

- **Source**: {source}
- **Date**: {date_str}
- **Tags**: {tags}

{body}
"""

    with open(out_path, 'w') as f:
        f.write(template)

    print(f"Saved: {out_path}")


if __name__ == '__main__':
    main()
