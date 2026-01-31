-module(gaussian_ffi).
-export([set_document_class/1, get_preferred_color_scheme/0, save_settings/1, load_settings/0]).

set_document_class(_ClassName) ->
    % No-op for Erlang target (server-side)
    nil.

get_preferred_color_scheme() ->
    % Default to light for Erlang target (server-side)
    <<"light">>.

save_settings(_DecimalPrecision) ->
    % No-op for Erlang target (server-side)
    nil.

load_settings() ->
    % Default to 3 for Erlang target (server-side)
    3.
