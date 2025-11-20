defmodule SubjectManagerWeb.CustomComponents do
  use Phoenix.Component
  use SubjectManagerWeb, :verified_routes

  attr(:status, :atom, required: true)
  attr(:class, :string, default: nil)

  def badge(assigns) do
    ~H"""
    <div class={[
      "rounded-md px-2 py-1 text-xs font-medium uppercase inline-block border",
      @status == :forward && "text-red-600 border-red-600",
      @status == :midfielder && "text-blue-600 border-blue-600",
      @status == :winger && "text-yellow-600 border-yellow-600",
      @status == :defender && "text-green-600 border-green-600",
      @status == :goalkeeper && "text-purple-600 border-purple-600",
      @class
    ]}>
      {@status}
    </div>
    """
  end
end
