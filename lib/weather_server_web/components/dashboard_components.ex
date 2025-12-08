defmodule WeatherServerWeb.DashboardComponents do
  use Phoenix.Component

  attr :title, :string, required: true

  attr :value_id, :string, default: nil

  attr :class, :string, default: ""

  slot :inner_block, required: true

  def stat_card(assigns) do
    ~H"""
    <div class={[
      "
        card
        bg-gradient-to-b from-base-100 to-base-100/85
        border border-base-300/80
        shadow-md hover:shadow-xl
        transition-all duration-200

        h-full relative overflow-hidden
        rounded-xl backdrop-blur-sm

        hover:-translate-y-[1px]
      ",
      @class
    ]}>
      <div class="card-body items-center p-3 gap-1">
        <div class="stat-title text-[11px] uppercase tracking-[0.8px] mb-1 text-base-content/70">
          {@title}
        </div>
        <div
          id={@value_id}
          class="stat-value text-[22px] font-bold text-base-content drop-shadow-sm"
        >
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end
end
