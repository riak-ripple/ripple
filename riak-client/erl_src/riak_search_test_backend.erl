%% -------------------------------------------------------------------
%%
%% Copyright (c) 2007-2010 Basho Technologies, Inc.  All Rights Reserved.
%%
%% -------------------------------------------------------------------

-module(riak_search_test_backend).
-behavior(riak_search_backend).

-export([
         reset/0,
         start/2,
         stop/1,
         index/2,
         delete/2,
         stream/6,
         range/8,
         info/5,
         fold/3,
         is_empty/1,
         drop/1
        ]).
-export([
         stream_results/3
        ]).

-include_lib("riak_search/include/riak_search.hrl").

-record(state, {partition, table}).

reset() ->
    {ok, Ring} = riak_core_ring_manager:get_my_ring(),
    [ ets:delete_all_objects(list_to_atom("rs" ++ integer_to_list(P))) ||
        P <- riak_core_ring:my_indices(Ring) ],
    riak_search_config:clear(),
    ok.

start(Partition, _Config) ->
    Table = ets:new(list_to_atom("rs" ++ integer_to_list(Partition)),
                    [named_table, public, ordered_set]),
    {ok, #state{partition=Partition, table=Table}}.

stop(State) ->
    maybe_delete(State).

index(IFTVPKList, #state{table=Table}=State) ->
    lists:foreach(
      fun({I, F, T, V, P, K}) ->
              Key = {b(I), b(F), b(T), b(V)},
              case ets:lookup(Table, Key) of
                  [{_, _, ExistingKeyClock}] ->
                      if ExistingKeyClock > K ->
                              %% stored data is newer
                              ok;
                         true ->
                              %% stored data is older
                              ets:update_element(Table, Key,
                                                 [{2, P},{3, K}])
                      end;
                  [] ->
                      ets:insert(Table, {Key, P, K})
              end
      end,
      IFTVPKList),
    {reply, {indexed, node()}, State}.

delete(IFTVKList, State) ->
    Table = State#state.table,
    lists:foreach(fun(IFTVK) -> delete_fun(IFTVK, Table) end, IFTVKList),
    {reply, {deleted, node()}, State}.

delete_fun({I, F, T, V, K}, Table) ->
    Key = {b(I), b(F), b(T), b(V)},
    case ets:lookup(Table, Key) of
        [{Key, _Props, ExistingKeyClock}] ->
            if ExistingKeyClock > K ->
                    %% stored data is newer
                    ok;
               true ->
                    %% stored data is older
                    ets:delete(Table, Key)
            end;
        [] ->
            ok
    end;
delete_fun({I, F, T, V, _P, K}, Table) ->
    %% copied idea from merge_index_backend
    %% other operations include Props, though delete shouldn't
    delete_fun({I, F, T, V, K}, Table).

info(Index, Field, Term, Sender, State) ->
    Count = ets:select_count(State#state.table,
                             [{{{b(Index), b(Field), b(Term), '_'},
                                '_', '_'},
                               [],[true]}]),
    riak_search_backend:info_response(Sender, [{Term, node(), Count}]),
    noreply.

-define(STREAM_SIZE, 100).

range(Index, Field, StartTerm, EndTerm, _Size, FilterFun, Sender, State) ->
    ST = b(StartTerm),
    ET = b(EndTerm),
    spawn(riak_search_ets_backend, stream_results,
          [Sender,
           FilterFun,
           ets:select(State#state.table,
                      [{{{b(Index), b(Field), '$1', '$2'}, '$3', '_'},
                        [{'>=', '$1', ST}, {'=<', '$1', ET}],
                        [{{'$2', '$3'}}]}],
                      ?STREAM_SIZE)]),
    noreply.

stream(Index, Field, Term, FilterFun, Sender, State) ->
    spawn(riak_search_ets_backend, stream_results,
          [Sender,
           FilterFun,
           ets:select(State#state.table,
                      [{{{b(Index), b(Field), b(Term), '$1'}, '$2', '_'},
                        [], [{{'$1', '$2'}}]}],
                      ?STREAM_SIZE)]),
    noreply.

stream_results(Sender, FilterFun, {Results0, Continuation}) ->
    case lists:filter(fun({V,P}) -> FilterFun(V, P) end, Results0) of
        [] ->
            ok;
        Results ->
            riak_search_backend:response_results(Sender, Results)
    end,
    stream_results(Sender, FilterFun, ets:select(Continuation));
stream_results(Sender, _, '$end_of_table') ->
    riak_search_backend:response_done(Sender).

fold(FoldFun, Acc, State) ->
    Fun = fun({{I,F,T,V},P,K}, {OuterAcc, {{I,{F,T}},InnerAcc}}) ->
                  %% same IFT, just accumulate doc/props/clock
                  {OuterAcc, {{I,{F,T}},[{V,P,K}|InnerAcc]}};
             ({{I,F,T,V},P,K}, {OuterAcc, {FoldKey, VPKList}}) ->
                  %% finished a string of IFT, send it off
                  %% (sorted order is assumed)
                  NewOuterAcc = FoldFun(FoldKey, VPKList, OuterAcc),
                  {NewOuterAcc, {{I,{F,T}},[{V,P,K}]}};
             ({{I,F,T,V},P,K}, {OuterAcc, undefined}) ->
                  %% first round through the fold - just start building
                  {OuterAcc, {{I,{F,T}},[{V,P,K}]}}
          end,
    {OuterAcc0, Final} = ets:foldl(Fun, {Acc, undefined}, State#state.table),
    OuterAcc = case Final of
                   {FoldKey, VPKList} ->
                       %% one last IFT to send off
                       FoldFun(FoldKey, VPKList, OuterAcc0);
                   undefined ->
                       %% this partition was empty
                       OuterAcc0
               end,
    {reply, OuterAcc, State}.

is_empty(State) ->
    0 == ets:info(State#state.table, size).

drop(State) ->
    maybe_delete(State).

maybe_delete(State) ->
    case lists:member(State#state.table, ets:all()) of
        true ->
            ets:delete(State#state.table),
            ok;
        false ->
            ok
    end.

b(Binary) when is_binary(Binary) -> Binary;
b(List) when is_list(List) -> iolist_to_binary(List).
