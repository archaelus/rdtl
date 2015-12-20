-module('rdtl_prv').

-export([init/1, do/1, format_error/1]).

-define(PROVIDER, 'rdtl').
-define(DEPS, [app_discovery]).

-define(DEBUG(Str, Args), rebar_log:log(debug, Str, Args)).
-define(INFO(Str, Args), rebar_log:log(info, Str, Args)).
-define(WARN(Str, Args), rebar_log:log(warn, Str, Args)).
-define(ERROR(Str, Args), rebar_log:log(error, Str, Args)).

%% ===================================================================
%% Public API
%% ===================================================================
-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
    Provider = providers:create([
            {name, ?PROVIDER},            % The 'user friendly' name of the task
            {module, ?MODULE},            % The module implementation of the task
            {bare, true},                 % The task can be run by the user, always true
            {deps, ?DEPS},                % The list of dependencies
            {example, "rebar3 rdtl"}, % How to use the plugin
            {opts,
             []},                   % list of options understood by the plugin
            {short_desc, "Erlydtl plugin for rebar3"},
            {desc, "Erlydtl plugin for rebar3"}
    ]),
    {ok, rebar_state:add_provider(State, Provider)}.


-spec do(rebar_state:t()) -> {ok, rebar_state:t()} | {error, string()}.
do(State) ->
    rebar_utils:update_code(rebar_state:code_paths(State, all_deps)),
    erlydtl:module_info(),
    Apps = rebar_state:project_apps(State),
    TmplInfo = [app_template_info(A) || A <- Apps],
    ?DEBUG("Template app info: ~p", [TmplInfo]),
    ToCompile = find_templates(TmplInfo),
    ?DEBUG("To compile: ~p", [ToCompile]),
    case compile_templates(ToCompile, State) of
        [] ->
            {ok, State};
        Errors ->
            {error, Errors}
    end.

-spec format_error(any()) ->  iolist().
format_error(Reason) ->
    io_lib:format("~p", [Reason]).

find_templates(TmplInfo) ->
    [ {OutDir,
       filelib:wildcard(filename:join(TmplDir, "*.rdtl"))}
      || {TmplDir, OutDir} <- TmplInfo ].


app_template_info(App) ->
    {filename:join([rebar_app_info:dir(App),
                    "templates"]),
     rebar_app_info:ebin_dir(App)}.

compile_templates(TmplInfo, State) ->
    lists:filter(fun edtl_error/1,
                 [compile_template(Template, OutDir, State)
                  || {OutDir, Templates} <- TmplInfo,
                     Template <- Templates]).

compile_template(Template, OutDir, State) ->
    ModuleName = list_to_atom(filename:basename(Template, ".rdtl")),
    ?INFO("Compiling template ~p", [ModuleName]),
    erlydtl:compile_file(Template, ModuleName,
                         [{out_dir, OutDir}, no_load,
                          return_errors, return_warnings]).

edtl_error({ok, _, _}) -> false;
edtl_error(_) -> true.
