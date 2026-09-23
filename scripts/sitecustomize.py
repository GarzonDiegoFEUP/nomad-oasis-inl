"""Runtime compatibility patches for the bundled NOMAD environment."""

from __future__ import annotations

import functools
import inspect


def patch_msection_stable_references() -> bool:
    try:
        from nomad.metainfo.metainfo import MSection
    except Exception:
        return False

    method = MSection.m_to_dict
    try:
        signature = inspect.signature(method)
    except (TypeError, ValueError):
        return False

    if "stable_references" in signature.parameters or getattr(
        method, "_stable_references_compat", False
    ):
        return False

    @functools.wraps(method)
    def wrapper(self, *args, **kwargs):
        kwargs.pop("stable_references", None)
        return method(self, *args, **kwargs)

    wrapper._stable_references_compat = True
    MSection.m_to_dict = wrapper
    return True


patch_msection_stable_references()
