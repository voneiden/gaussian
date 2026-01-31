-module(gaussian_ffi).
-export([set_document_class/1, get_preferred_color_scheme/0]).

set_document_class(_ClassName) ->
    % No-op for Erlang target (server-side)
    nil.

get_preferred_color_scheme() ->
    % Default to light for Erlang target (server-side)
    <<"light">>.
