defmodule TodoAppWeb.TodoAppLive do
  use TodoAppWeb, :live_view

  @spec mount(any(), any(), any()) :: {:ok, any()}
  def mount(_params, _session, socket) do
    # dbg("mount debugging")
    todos = GenServer.call(:todos, :get_todos)

    {:ok,
     assign(socket,
       input: "",
       todos: todos,
       light_mode: true,
       show_all: true,
       show_completed: false,
       show_incomplete: false
     )}
  end

  def handle_event("light_mode", _params, socket) do
    new_light_mode = not socket.assigns.light_mode
    IO.inspect(new_light_mode, label: "New Light Mode")
    {:noreply, assign(socket, light_mode: new_light_mode)}
  end

  def handle_event("enter_pressed", %{"user_input" => value}, socket) do
    todo = String.trim(value)
    # IO.inspect(todo, label: "Check todo")

    if todo != "" do
      TodoApp.TodoServer.add_todo(todo)
      todos = TodoApp.TodoServer.todos()
      {:noreply, assign(socket, input: "", todos: todos)}
    else
      # IO.puts("Empty input, not adding todo")
      {:noreply, socket}
    end
  end

  def handle_event("update_input", %{"user_input" => val}, socket) do
    {:noreply, assign(socket, input: val)}
  end

  # Action: Show All Todos
  def handle_event("show_todos", _param, socket) do
    {:noreply,
     assign(socket,
       show_all: true,
       show_completed: false,
       show_incomplete: false
     )}
  end

  # Action: Show Completed Todos
  def handle_event("show_completed", _param, socket) do
    {:noreply,
     assign(socket,
       show_all: false,
       show_completed: true,
       show_incomplete: false
     )}
  end

  # Action: Show Incomplete Todos
  def handle_event("show_incomplete", _param, socket) do
    {:noreply,
     assign(socket,
       show_all: false,
       show_completed: false,
       show_incomplete: true
     )}
  end
  # Action: Toggle Todo Completion
  def handle_event("toggle_todo", %{"id" => id}, socket) do
    id = String.to_integer(id)
    TodoApp.TodoServer.toggle_completed(id)
    todos = TodoApp.TodoServer.todos()

    {:noreply, assign(socket, todos: todos)}
  end

  def handle_event("delete_todo", %{"id" => id}, socket) do
    id = String.to_integer(id)
    TodoApp.TodoServer.delete_todo(id)
    todos = TodoApp.TodoServer.todos()
    {:noreply, assign(socket, todos: todos)}
  end

  def handle_event("clear_completed", _params, socket) do
    TodoApp.TodoServer.delete_completed()
    todos = TodoApp.TodoServer.todos()
    {:noreply, assign(socket, todos: todos)}
  end

  defp visible_todos(todos, true, _, _), do: todos
  defp visible_todos(todos, _, true, _), do: Enum.filter(todos, & &1.is_completed)
  defp visible_todos(todos, _, _, true), do: Enum.filter(todos, & !&1.is_completed)
  defp visible_todos(todos, _, _, _), do: todos

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <main class={"font-josefinSans w-full flex flex-col text-grey_11 items-center min-h-screen" <> if @light_mode, do: " bg-gb_11", else: " bg-blue_00" }>
     <img
        class="absolute w-full"
        src={if @light_mode, do: "/images/bg-desktop-light.jpg", else: "/images/bg-desktop-dark.jpg"}
        alt="Background Image" />
      <div class="relative top-0 mt-20 w-full max-w-[580px]">
        <header class="w-full flex justify-between">
          <h1 class="text-4xl font-bold tracking-[0.6em]">TODO</h1>
          <button phx-click="light_mode">light btn</button>
        </header>

        <div>
          <section class={"mb-8 mt-12 flex h-16 items-center gap-x-5 p-5 rounded-md" <> if @light_mode, do: " bg-grey_11", else: " bg-desaturated_blue00"}>
            <div class="w-7 h-7 border border-gb_0 rounded-full"></div>
            <form phx-submit="enter_pressed" class="w-full">
              <input
                class={"text-lg w-full h-full border-none focus:outline-none focus:ring-0 focus:border-none" <> if @light_mode, do: " bg-grey_11 placeholder-gb_0 text-gb_001", else: " bg-desaturated_blue00 placeholder-gb_1"}
                placeholder="Create a new todo..."
                type="text"
                name="user_input"
                value={@input}
                phx-change="update_input"
                autocomplete="off" />
            </form>
          </section>

          <section class={"rounded-md shadow-lg"  <> if @light_mode, do: " bg-grey_11", else: " bg-desaturated_blue00"}>
            <ul>
             <%!-- <%=  for todo <-@todos do %> --%>
              <%= for todo <- visible_todos(@todos, @show_all, @show_completed, @show_incomplete) do %>
                <li class={"flex items-center border-b h-16 p-5 gap-x-6" <> if @light_mode, do: " border-gb_11", else: " border-gb_001"}>
                 <%!-- todo.status === "completed" ? <div id="completed_todo"> :  <div id="incomplete_todo"> --%>
                  <button
                    class="completed_todo"
                    phx-click="toggle_todo"
                    phx-value-id={todo.id}>

                    <%= if todo.is_completed == false do %>
                      <div class={"rounded-full w-[26px] h-[26px]" <> if @light_mode, do: " bg-grey_11", else: " bg-desaturated_blue00"}></div>
                    <% end %>
                  </button>
                  <%= if todo.is_completed == false do %>
                   <%!-- <%= if String.downcase(todo.is_completed) == "incomplete" do %> --%>
                    <h1 class={"text-lg" <> if @light_mode, do: " text-gb_001", else: " text-light_grayish_blue"}><%= todo.todo %></h1>
                  <% else %>
                    <s class={"text-lg line-through" <> if @light_mode, do: " text-gb_1", else: " text-gb_001"}><%= todo.todo %></s>
                  <% end %>

                  <button class={"ml-auto" <> if @light_mode, do: " text-gb_02", else: " text-light_grayish_blue"} phx-click="delete_todo" phx-value-id={todo.id}>X</button>
                </li>
              <% end %>
            </ul>

            <div class="text-gb_02 flex justify-between items-center p-5">
              <p class="text-sm">
                <%= length(@todos) %> <span><%= if length(@todos) > 1, do: "items", else: "item" %> left</span>
              </p>

              <div class="flex gap-x-5 font-medium">
                <button class={(if @light_mode, do: "hover:text-gb_001 ", else: "hover:text-white ") <> (if @show_all, do: " text-brightBlue", else: "")} phx-click="show_todos">All</button>
                <button class={(if @light_mode, do: "hover:text-gb_001 ", else: "hover:text-white ") <> (if @show_incomplete, do: " text-brightBlue", else: "")} phx-click="show_incomplete">Active</button>
                <button class={(if @light_mode, do: "hover:text-gb_001 ", else: "hover:text-white ") <> (if @show_completed, do: " text-brightBlue", else: "")} phx-click="show_completed">Completed</button>
              </div>

              <button class={if @light_mode, do: "hover:text-gb_001 ", else: "hover:text-white "} phx-click="clear_completed">Clear completed</button>
            </div>
          </section>
        </div>
      </div>
    </main>
    """
  end
end
