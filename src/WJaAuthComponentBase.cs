// Copyright (c) Oleksandr Viktor (UkrGuru). All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.

using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.AspNetCore.Components.Forms;
using System.Security.Claims;
using Telerik.Blazor.Components;

namespace UkrGuru.WebJobs.Admin;

public class WJaAuthComponentBase : ComponentBase
{
    [CascadingParameter]
    protected Task<AuthenticationState> AuthenticationStateTask { get; set; }

    [Parameter]
    public string Title { get; set; }
    
    protected string ErrMsg { get; set; }

    protected async Task<ClaimsPrincipal> GetAuthUser() => (await AuthenticationStateTask)?.User;
    protected async Task<string> GetLoginName() => (await GetAuthUser())?.Identity?.Name ?? "Guest";

    protected virtual object ID { get; }

    protected virtual async Task InitData() { await Task.CompletedTask; }
    protected virtual async Task LoadData() { await Task.CompletedTask; }
    protected virtual async Task GetItemAsync(GridCommandEventArgs args) { await Task.CompletedTask; }
    protected virtual async Task SetItemAsync(EditContext editContext) { await Task.CompletedTask; }
    protected virtual async Task InsItemAsync(GridCommandEventArgs args) { await Task.CompletedTask; }
    protected virtual async Task UpdItemAsync(GridCommandEventArgs args) { await Task.CompletedTask; }
    protected virtual async Task DelItemAsync(GridCommandEventArgs args) { await Task.CompletedTask; }

    protected override async Task OnInitializedAsync()
    {
        ErrMsg = null;
        try
        {
            await InitData();

            await LoadData();
        }
        catch (Exception ex)
        {
            ErrMsg = $"Error: {ex.Message}";
            await LogHelper.LogErrorAsync($"{Title}/OnInitializedAsync", new { ex.Message });
        }
    }

    protected async Task Refresh()
    {
        ErrMsg = null;
        try
        {
            await LoadData();
        }
        catch (Exception ex)
        {
            ErrMsg = $"Error: {ex.Message}";
            await LogHelper.LogErrorAsync($"{Title}/Refresh", new { ex.Message });
        }
    }

    protected async Task CreateHandler(GridCommandEventArgs args)
    {
        ErrMsg = null;
        try
        {
            await InsItemAsync(args);

            await LoadData();

            ErrMsg = $"Created successfully.";
            await LogHelper.LogInformationAsync($"{Title}/CreateHandler", new { Message = ErrMsg });
        }
        catch (Exception ex)
        {
            ErrMsg = $"Error: {ex.Message}";
            await LogHelper.LogErrorAsync($"{Title}/CreateHandler", new { ex.Message });
        }
    }

    protected async Task UpdateHandler(GridCommandEventArgs args)
    {
        ErrMsg = null;
        try
        {
            await UpdItemAsync(args);

            await LoadData();

            ErrMsg = $"Updated successfully.";
            await LogHelper.LogInformationAsync($"{Title}/UpdateHandler", new { ID, Message = ErrMsg });
        }
        catch (Exception ex)
        {
            ErrMsg = $"Error: {ex.Message}";
            await LogHelper.LogErrorAsync($"{Title}/UpdateHandler", new { ID, ex.Message });
        }
    }

    protected async Task DeleteHandler(GridCommandEventArgs args)
    {
        ErrMsg = null;
        try
        {
            await DelItemAsync(args);

            await LoadData();

            ErrMsg = $"Deleted successfully.";
            await LogHelper.LogInformationAsync($"{Title}/DeleteHandler", new { ID, Message = ErrMsg });
        }
        catch (Exception ex)
        {
            ErrMsg = $"Error: {ex.Message}";
            await LogHelper.LogErrorAsync($"{Title}/DeleteHandler", new { ID, ex.Message });
        }
    }

    protected async Task SubmitHandler(EditContext editContext)
    {
        ErrMsg = null;
        if (editContext.Validate())
        {
            await SetItemAsync(editContext);

            ErrMsg = $"Submit successfully.";
            await LogHelper.LogInformationAsync($"{Title}/SubmitHandler", new { ID, Message = ErrMsg });
        }
        else
        {
            ErrMsg = $"Error: Invalid Data. Submit canceled.";
            await LogHelper.LogErrorAsync($"{Title}/SubmitHandler", new { ID, Message = ErrMsg });
        }
    }
}