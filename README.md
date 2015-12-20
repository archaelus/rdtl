rdtl
=====

Erlydtl plugin for rebar3

Build
-----

    $ rebar3 compile

Use
---

Add the plugin to your rebar config:

    {plugins, [
        { rdtl, ".*", {git, "git@host:user/rdtl.git", {tag, "0.1.0"}}}
    ]}.

Then just call your plugin directly in an existing application:


    $ rebar3 rdtl
    ===> Fetching rdtl
    ===> Compiling rdtl
    <Plugin Output>
