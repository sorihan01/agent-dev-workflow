# Generated views

- **A view is never a home.** `views/*.md` are built by `tools/build-view.py` from the documents that own each fact. Never edit one by hand; change the source, then rebuild.
- **No typed facts.** A number in a view comes from a `count:` rule; text is copied from its source. If a fact has no source document yet, it doesn't go in the view.
- **Stale is a failure.** `python3 tools/build-view.py --check` must pass before a task that changed a source is done. Rebuild and commit the view with the change.
