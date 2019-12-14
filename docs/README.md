[![Gem Version](https://badge.fury.io/rb/action_policy.svg)](https://badge.fury.io/rb/action_policy)
[![Build Status](https://travis-ci.org/palkan/action_policy.svg?branch=master)](https://travis-ci.org/palkan/action_policy)

## Action Policy

> Authorization framework for Ruby and Rails.
<br>Composable. Extensible. Performant.

**NOTE:** this documentation is for the version "0.3.0+".

## What is it?

_Authorization_ is an act of giving **someone** official
permission to **do something** (to not be confused with [_authentication_](https://en.wikipedia.org/wiki/Authentication)).

Action Policy provides flexible tools to build an _authorization layer_ for your application.

<div class="chart-container">
  <img src="assets/images/layer.svg" alt="Authorization layer" width="80%">
</div>

**NOTE:** Action Policy does not force you to use a specific authorization model (i.e., roles, permissions, etc.) and does not provide one. It only answers a single question: **How to verify access?**

## Where to go from here?
- [Quick start](./quick_start.md)
- [Using with Rails](./rails.md)
- [Using with other Ruby frameworks](./non_rails.md)
- [Using with GraphQL Ruby](./graphql.md)

## Project State

The project is being used in production since mid 2018. Major features have been implemented, API has been stabilized. Check out our [development board](https://github.com/palkan/action_policy/projects/1) to see what's coming next.

## History

Action Policy gem is an _extraction_-kind of a library. Most of the code has been used in production for several years in different [Evil Martians][] projects.

We have decided to collect all our authorization techniques and pack them into a standalone gem–and that is how Action Policy was born!

## What about the existing solutions?

Why did we decide to build our own authorization gem instead of using the existing solutions, such as [Pundit][] and [CanCanCan][]?

**TL;DR they didn't solve all of our problems.**

[Pundit][] has been our framework of choice for a long time. Being too _dead-simple_, it required a lot of hacking to fulfill business logic requirements.

These _hacks_ later became Action Policy (initially, we even called it "Pundit, re-visited").

We also took a few ideas from [CanCanCan][]—such as [default rules and rule aliases](./aliases.md).

It is also worth noting that Action Policy (despite having a _Railsy_ name) is designed to be **Rails-free**. On the other hand, it contains some Rails-specific extensions and seamlessly integrates into the framework.

So, what are the main reasons to consider Action Policy as your authorization tool?

- **Performance**: multiple [caching strategies](./caching.md) out-of-the-box make authorization overhead as small as possible–especially useful when your rules involve DB queries; you can also monitor the performance and detect the bottlenecks using the built-in [instrumentation](./instrumentation) features.

- **Composition & Customization**: use [only the features you need](./custom_policy.md) or easily extend the functionality–it's just Ruby classes and modules, (almost) zero magic! And you can add authorization [anywhere in your code](./non_rails.md), not only in controllers.

- **Code Organization**: use [namespaces](./namespaces.md) to organize your policies (for example, when you have multiple authorization strategies); add [pre-checks](./pre_checks.md) to make rules more readable and better express your business-logic.

- **...and more**: [testability](./testing.md), [i18n](./i18n.md) integrations, [actionable errors](./reasons.md).

Learn more about the motivation behind the Action Policy and its features by watching this [RailsConf talk](https://www.youtube.com/watch?v=NVwx0DARDis).

## Resources

- RubyRussia, 2019 "Welcome, or access denied?" talk ([video](https://www.youtube.com/watch?v=y15a2g7v8i0) [RU], [slides](https://speakerdeck.com/palkan/rubyrussia-2019-welcome-or-access-denied))

- Seattle.rb, 2019 "A Denial!" talk [[slides](https://speakerdeck.com/palkan/seattle-dot-rb-2019-a-denial)]

- RailsConf, 2018 "Access Denied" talk [[video](https://www.youtube.com/watch?v=NVwx0DARDis), [slides](https://speakerdeck.com/palkan/railsconf-2018-access-denied-the-missing-guide-to-authorization-in-rails)]

<a href="https://evilmartians.com/?utm_source=action_policy">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54"></a>

[CanCanCan]: https://github.com/CanCanCommunity/cancancan
[Pundit]: https://github.com/varvet/pundit
[Evil Martians]: https://evilmartians.com
