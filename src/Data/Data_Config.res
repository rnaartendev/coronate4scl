/*
  Copyright (c) 2021 John Jackson. 

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/
module Option = Belt.Option

module ByeValue = {
  type t = Full | Half | Zero

  let toFloat = x =>
    switch x {
    | Full => 1.0
    | Half => 0.5
    | Zero => 0.0
    }

  let fromFloat = x =>
    switch x {
    | 0.5 => Half
    | 0.0 => Zero
    | _ => Full
    }

  let encode = data => data->toFloat->Js.Json.number

  let decode = json => Js.Json.decodeNumber(json)->Option.getExn->fromFloat
}

type alias = option<string>

type t = {
  avoidPairs: Data_Id.Pair.Set.t,
  byeValue: ByeValue.t,
  lastBackup: Js.Date.t,
  whiteAlias: alias,
  blackAlias: alias,
  externalBonus: int, //Adjustable points against External
}

let decode = json => {
  let d = Js.Json.decodeObject(json)->Option.getExn
  {
    avoidPairs: d->Js.Dict.get("avoidPairs")->Option.getExn->Data_Id.Pair.Set.decode,
    byeValue: d->Js.Dict.get("byeValue")->Option.getExn->ByeValue.decode,
    lastBackup: d
    ->Js.Dict.get("lastBackup")
    ->Option.flatMap(Js.Json.decodeString)
    ->Option.getExn
    ->Js.Date.fromString,
    whiteAlias: d->Js.Dict.get("whiteAlias")->Option.flatMap(Js.Json.decodeString),
    blackAlias: d->Js.Dict.get("blackAlias")->Option.flatMap(Js.Json.decodeString),
    /* : safe decoding for the bonus value */
    externalBonus: d
    ->Js.Dict.get("externalBonus")
    ->Option.flatMap(Js.Json.decodeNumber)
    ->Option.getWithDefault(10.0) // fallback for existing data
    ->Belt.Float.toInt,
  }
}

let encodeAlias = o =>
  switch o {
  | None => Js.Json.null
  | Some(s) => Js.Json.string(s)
  }

let encode = data =>
  Js.Dict.fromArray([
    ("avoidPairs", data.avoidPairs->Data_Id.Pair.Set.encode),
    ("byeValue", data.byeValue->ByeValue.encode),
    ("lastBackup", data.lastBackup->Js.Date.toJSONUnsafe->Js.Json.string),
    ("whiteAlias", encodeAlias(data.whiteAlias)),
    ("blackAlias", encodeAlias(data.blackAlias)),
    /* Convert int back to JSON number */
    ("externalBonus", data.externalBonus->Belt.Float.fromInt->Js.Json.number),
  ])->Js.Json.object_

let default = {
  byeValue: Full,
  avoidPairs: Belt.Set.make(~id=Data_Id.Pair.id),
  lastBackup: Js.Date.fromFloat(0.0),
  whiteAlias: None,
  blackAlias: None,
  externalBonus: 10, // Standard C4SCL value
}

let aliasEmpty = None
let alias = s =>
  switch s {
  | "" => None
  | s => Some(s)
  }

let aliasToStringWhite = t =>
  switch t.whiteAlias {
  | None => "White"
  | Some(s) => s
  }

let aliasToStringBlack = t =>
  switch t.blackAlias {
  | None => "Black"
  | Some(s) => s
  }

let aliasToOption = o => o
