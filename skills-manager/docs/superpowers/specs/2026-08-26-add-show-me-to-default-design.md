# Add `show-me` to the default Skill preset

## Goal

Install HumanLayer's `show-me` Skill in every destination that uses the
`default` preset, while preserving upstream updates and avoiding installation
of unrelated Skills from the same repository.

## Design

Add `show-me` to `presets.default.skills` as a named single-Skill Source. Add a
matching `sources.show-me` entry that checks out `humanlayer/skills` and points
`skill` at `plugins/show-me/skills/show-me`.

This follows the existing `archify`, `find-skills`, and other single-Skill
Source convention: the Source name is also the final installed Skill name.
The manager will therefore activate the Source only because the default preset
references `show-me`, then link that exact Skill directory into every default
installation destination.

## Documentation

Update the documented default Skill count from 59 to 60. No installer or
destination configuration changes are required.

## Verification

1. Validate `config.yaml` with `yq`.
2. Confirm the default preset contains `show-me` and its Source resolves to the
   expected GitHub repository and Skill path.
3. Run the installer's non-mutating preview and confirm `show-me` is included
   or, before its first checkout, reported as the only newly missing active
   Source.
