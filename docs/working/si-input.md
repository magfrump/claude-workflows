# SI Input

## Feedback
<!-- What worked, what didn't, what you noticed since last run -->

We saw a full run fail for BATS test when the test failure was from a change outside of the self improvement script. If a full round of features fails, this should trigger a health check to see if the failures are preexisting and correct them before returning to feature generation.

## Priorities
<!-- What should the next run focus on? -->

Divergent design comes from a "double diamond" technique, which involves diverging on *purpose* first, then diverging on *implementation*. I would like to see the divergent design make that double diamond explicit when relevant.

## Off-limits
<!-- Topics or files to avoid touching -->

## Context
<!-- Current project focus, upcoming deadlines, anything else relevant -->

I recently wrote up work on the Metaformalism Coagent here: "/mnt/c/Users/magfr/Downloads/MFC post drafts (1).md" and made some arguments about LLM interfaces. I also did a thorough review of design techniques and wrote up a summary document at "/mnt/c/Users/magfr/Downloads/design_space.md".

I expect 3d modeling, both for 3d printing and for video games, to start coming up soon and would like to have guidance and tools for exploring and understanding that space.