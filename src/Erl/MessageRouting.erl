-module(erl_messageRouting@foreign).

-export([ startRouterImpl/4
        , maybeStartRouterImpl/4
        , stopRouter/1
        , stopRouterFromCallback/0
        ]).

%% RegisterListener is of type Effect msg (so is effectively a function with no args)
%% DeregisterListener is of type (msg -> Effect Unit) and takes this  value and gives us an Effect
%% with which we will need to invoke manually here
startRouterImpl(Ref, RegisterListener, DeregisterListener, Callback) ->
  fun() ->
      {just, Result } = (maybeStartRouterImpl(Ref, fun() -> { just, RegisterListener() } end, DeregisterListener, Callback))(),
      Result
  end.

maybeStartRouterImpl(Ref, RegisterListener, DeregisterListener, Callback) ->
  Recipient = self(),
  Fun = fun Fun(Handle, MonitorRef) ->
              receive
                {stop, From, StopRef} ->
                  (DeregisterListener(Handle))(),
                  demonitor(MonitorRef),
                  From ! {stopped, StopRef},
                  exit(normal);
                {'DOWN', MonitorRef, _, _, _} ->
                  (DeregisterListener(Handle))(),
                  exit(normal);
                Msg ->
                  try
                    (Callback(Msg))()
                  catch
                    Class:Reason:Stack ->
                      Recipient ! {error, {message_router_callback_failed, {Class, Reason, Stack}}},
                      exit(error)
                  end,
                  Fun(Handle, MonitorRef)
              end
           end,
  fun() ->
    Pid = spawn(fun() ->
                    MaybeHandle = RegisterListener(),
                    case MaybeHandle of
                      {just, Handle} ->
                        Recipient ! { start_result, Handle },
                        MonitorRef = monitor(process, Recipient),
                        Fun(Handle, MonitorRef);
                      {nothing} ->
                        Recipient ! { start_result, undefined }
                    end
                end),
    receive
      { start_result, undefined } ->
        {nothing};
      { start_result, Result } ->
        {just, (Ref(Result))(Pid) }
    end
  end.

stopRouterFromCallback() ->
  Self = self(),
  fun() ->
      Ref = make_ref(),
      Self ! {stop, self(), Ref},
      ok
  end.

stopRouter({_, _, Pid}) ->
  fun() ->
      Ref = make_ref(),
      Pid ! {stop, self(), Ref},
      receive
        {stopped, Ref} -> ok
      end,
      ok
  end.
