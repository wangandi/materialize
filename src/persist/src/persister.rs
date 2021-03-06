// Copyright Materialize, Inc. and contributors. All rights reserved.
//
// Use of this software is governed by the Business Source License
// included in the LICENSE file.
//
// As of the Change Date specified in that file, in accordance with
// the Business Source License, use of this software will be governed
// by the Apache License, Version 2.0.

//! An abstraction for multiplexed streams of persisted data.

/// An isolated, consistent read of previously written (Key, Value, Time, Diff)
/// updates.
pub trait Snapshot {
    /// A partial read of the data in the snapshot.
    ///
    /// Returns true if read needs to be called again for more data.
    fn read<E: Extend<((String, String), u64, isize)>>(&mut self, buf: &mut E) -> bool;

    /// A full read of the data in the snapshot.
    #[cfg(test)]
    fn read_to_end(&mut self) -> Vec<((String, String), u64, isize)> {
        let mut buf = Vec::new();
        while self.read(&mut buf) {}
        buf.sort();
        buf
    }
}
