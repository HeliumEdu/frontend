abstract class UpdateGateState {}

class UpdateGateHidden extends UpdateGateState {}

/// An update is required, and the gate is waiting for the user to be idle on a
/// screen where no work can be lost.
class UpdateGateWaiting extends UpdateGateState {}

class UpdateGateShown extends UpdateGateState {}
