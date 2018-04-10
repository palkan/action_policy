[![Gem Version](https://badge.fury.io/rb/action_policy.svg)](https://badge.fury.io/rb/action_policy)
[![Build Status](https://travis-ci.org/palkan/action_policy.svg?branch=master)](https://travis-ci.org/palkan/action_policy)

## Action Policy

> authorization framework for Ruby and Rails applications.

## What is it?

_Authorization_ is an act of giving **someone** official
permission to **do something** (don't mess with [_authentication_](https://en.wikipedia.org/wiki/Authentication)).

Action Policy provides flexible tools to build _authorization layer_ for your applications.

_TODO: схема с местом авторизации в приложении_

**NOTE:** Action Policy doesn't force you to use specific authorization model (i.e. roles, permissions, etc.) and doesn't provide one. It answers the only one question: **How to verify access?**

## History

Action Policy gem is an _extraction-kind_ of library. Most of the code has been used in production for several years in different [Evil Martians][] projects.

We decided to collect all our authorization techniques and pack them into a standalone gem–that's how Action Policy was born!

## What about the existing solutions?

Why did we decide to build our own authorization gem instead of using the existing solutions, such as [Pundit][] and [CanCanCan][], for example?

**TL;DR they didn't solve all of our problems.**

[Pundit][] has been our framework of a choice for a long time. Being too _dead-simple_, it required a lot of hacking to fulfill business-logic requirements.

These _hacks_ turned into Action Policy (we even call it "Pundit, re-visited").

We also took a few ideas from [CanCanCan][], such as default rules and rules aliases.

It's also worth noting, that Action Policy (despite from _Railsy_ name) is designed to be **Rails-free**. From the other hand, it contains some Rails-specific extensions and seamlessly integrates into the framework.

<a href="https://evilmartians.com/">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54"></a>

[CanCanCan]: https://github.com/CanCanCommunity/cancancan
[Pundit]: https://github.com/varvet/pundit
[Evil Martians]: https://evilmartians.com
