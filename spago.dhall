{-
Welcome to a Spago project!
You can edit this file as you like.
-}
{ name =
    "purescript-erl-message-routing"
, backend =
    "purerl"
, dependencies =
    [ "prelude"
    , "maybe"
    , "effect"
    , "erl-process"
    ]
, packages =
    ./packages.dhall
, sources =
    [ "src/**/*.purs" ]
}
