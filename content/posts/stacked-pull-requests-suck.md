---
title: Stacked Pull Requests Suck
date: 2026-10-12
categories:
  - Development
---

Stacked pull requests really do suck to deal with. When the change you are making is so large that it becomes extremely difficult to review and when you do have reviews and changes requested mid stack, it becomes a nightmare to have to rebase and untangle. There is a lot of book keeping involved in order to keep the stack up to date.

Stacked PRs seem to have garnered favor because developers are pushing larger and larger changes to the point that it is down right impossible for developers to review in totality, so the initial reaction is to simply stack them and try to keep the focus on just that change and disregard the later changes that build on it or use the new stuff being introduced.

Just create a pull request for ALL of the changes in one go. Be honest about it and don't try to hide stuff in multiple large pull requests.

Take pause for a moment and think about what you are doing. If the feature you are working on requires the entire stack, then you should just create a pull request for the entire set of changes. Make sure your work is done in smaller git commits so that a reviewer could walk the changes commit by commit rather than by pull request.

With coding agents and review agents, you are not reviewing everything line by line but your review agent will review the changes line by line and if you direct it to, it can review it commit by commit.

I believe a lot of developers fear `git rebase` and refuse to use it because someone in the past said "don't rewrite history". Those people are wrong. Do not rewrite main or master, but feature branches and bug fix branches? You bet your ass you should be rewriting and cleaning up those patch sets.

Stop using stacked pull requests. Get some help.
