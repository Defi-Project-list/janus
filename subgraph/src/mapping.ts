import { BigInt, Bytes, ByteArray } from "@graphprotocol/graph-ts"

import { DataUpdated } from "../generated/Janus/Janus"

import { IdentityData } from "../generated/schema"

export function handleDataUpdated(event: DataUpdated): void {
  let identityData = new IdentityData(event.params._address.toHexString());
  identityData.score = event.params._score;
  identityData.metaData = event.params._metaData;
  identityData.lastUpdated = event.params._lastUpdated;

  identityData.save()
}
