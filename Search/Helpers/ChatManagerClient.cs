using Newtonsoft.Json;
using VectorSearchAiAssistant.Service.Models.Chat;

namespace Search.Helpers;

public class ChatManagerClient(HttpClient httpClient)
{
    private List<Session>? _sessions = null;

    /// <summary>
    /// Returns list of chat session ids and names for left-hand nav to bind to (display Name and ChatSessionId as hidden)
    /// </summary>
    public async Task<List<Session>> GetAllChatSessionsAsync()
    {
        _sessions = await httpClient.GetFromJsonAsync<List<Session>>("/sessions");

        return _sessions!;
    }

    /// <summary>
    /// Returns the chat messages to display on the main web page when the user selects a chat from the left-hand nav
    /// </summary>
    public async Task<List<Message>> GetChatSessionMessagesAsync(string sessionId)
    {
        List<Message> chatMessages;

        if (_sessions is null || _sessions?.Count == 0)
        {
            return Enumerable.Empty<Message>().ToList();
        }

        var index = _sessions.FindIndex(s => s.SessionId == sessionId);

        chatMessages = await httpClient.GetFromJsonAsync<List<Message>>($"/sessions/{sessionId}/messages");

        // Cache results
        _sessions[index].Messages = chatMessages;

        return chatMessages;
    }

    /// <summary>
    /// User creates a new Chat Session.
    /// </summary>
    public async Task CreateNewChatSessionAsync()
    {
        var responseMessage = await httpClient.PostAsJsonAsync<Session>("/sessions", new());
        var content = await responseMessage.Content.ReadAsStringAsync();
        var session = JsonConvert.DeserializeObject<Session>(content);
        _sessions.Add(session);
    }

    /// <summary>
    /// Rename the Chat Session from "New Chat" to the summary provided by OpenAI
    /// </summary>
    public async Task RenameChatSessionAsync(string sessionId, string newChatSessionName, bool onlyUpdateLocalSessionsCollection = false)
    {
        ArgumentNullException.ThrowIfNull(sessionId);

        var index = _sessions.FindIndex(s => s.SessionId == sessionId);
        _sessions[index].Name = newChatSessionName;

        if (!onlyUpdateLocalSessionsCollection)
        {
            await httpClient.PostAsync($"/sessions/{sessionId}/rename?newChatSessionName={newChatSessionName}", null);
        }
    }

    /// <summary>
    /// User deletes a chat session
    /// </summary>
    public async Task DeleteChatSessionAsync(string sessionId)
    {
        ArgumentNullException.ThrowIfNull(sessionId);

        var index = _sessions.FindIndex(s => s.SessionId == sessionId);
        _sessions.RemoveAt(index);

        await httpClient.DeleteAsync($"/sessions/{sessionId}");
    }

    /// <summary>
    /// Receive a prompt from a user, Vectorize it from _openAIService Get a completion from _openAiService
    /// </summary>
    public async Task<string> GetChatCompletionAsync(string sessionId, string userPrompt)
    {
        ArgumentNullException.ThrowIfNull(sessionId);

        var responseMessage = await httpClient.PostAsJsonAsync($"/sessions/{sessionId}/completion", userPrompt);
        var content = await responseMessage.Content.ReadAsStringAsync();
        var completion = JsonConvert.DeserializeObject<Completion>(content);

        // Refresh the local messages cache:
        await GetChatSessionMessagesAsync(sessionId);
        return completion.Text;
    }

    public async Task<CompletionPrompt> GetCompletionPrompt(string sessionId, string completionPromptId)
    {
        ArgumentNullException.ThrowIfNullOrEmpty(sessionId);
        ArgumentNullException.ThrowIfNullOrEmpty(completionPromptId);

        var completionPrompt = await httpClient.GetFromJsonAsync<CompletionPrompt>($"/sessions/{sessionId}/completionprompts/{completionPromptId}");
        return completionPrompt;
    }

    public async Task<string> SummarizeChatSessionNameAsync(string sessionId, string prompt)
    {
        ArgumentNullException.ThrowIfNull(sessionId);

        var responseMessage = await httpClient.PostAsJsonAsync($"/sessions/{sessionId}/summarize-name", prompt);
        var content = await responseMessage.Content.ReadAsStringAsync();
        var response = JsonConvert.DeserializeObject<Completion>(content);

        await RenameChatSessionAsync(sessionId, response.Text, true);

        return response.Text;
    }

    /// <summary>
    /// Rate an assistant message. This can be used to discover useful AI responses for training, discoverability, and other benefits down the road.
    /// </summary>
    public async Task<Message> RateMessageAsync(string id, string sessionId, bool? rating)
    {
        ArgumentNullException.ThrowIfNull(id);
        ArgumentNullException.ThrowIfNull(sessionId);

        string url = rating == null
                    ? $"/sessions/{sessionId}/message/{id}/rate"
                    : $"/sessions/{sessionId}/message/{id}/rate?rating={rating}";

        var responseMessage = await httpClient.PostAsync(url, null);
        var content = await responseMessage.Content.ReadAsStringAsync();
        var message = JsonConvert.DeserializeObject<Message>(content);
        return message;
    }
}
