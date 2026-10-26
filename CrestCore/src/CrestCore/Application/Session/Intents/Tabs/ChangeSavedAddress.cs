using CrestCore.Application;
using CrestCore.Domain;

namespace CrestCore.Contracts;

/// Makes the address `Input` names, by its Space's address rules, the one a
/// saved or pinned tab belongs to. The page the tab shows stays where it is.
/// Refused with `UnsupportedAddress` when `Input` names no address, as blank
/// input or a search does, and with `NoSavedAddress` for a tab that belongs
/// nowhere.
public sealed record ChangeSavedAddress(Guid WorkspaceId, Guid SpaceId, Guid TabId, string Input) : SessionIntent(WorkspaceId) {
    #region Actions - Session

    internal override SessionEdit? Edit(NativeSessionAuthority workspace, SessionTurn turn) {
        var space = workspace.Editable(turn.Basis, SpaceId);
        var allowsInternalPages = turn.Pages?.OpensInternalPages ?? false;
        var resolution = AddressResolution.Resolve(Input,
            workspace.SearchCatalog.For(space.Settings.BrowsingPreferences, workspace.Kind.IsPrivate), allowsInternalPages);
        if (resolution is null || resolution.SearchQuery is not null) throw new Rejected(new UnsupportedAddress(Input));
        AddressResolution.ValidateUrl(resolution.Url, allowsInternalPages);
        return workspace.Organizing(turn.Basis, SpaceId, SyncStaging.Edit,
            edited => edited.Tab(TabId).ChangeSavedAddress(resolution.Url));
    }

    #endregion
}
