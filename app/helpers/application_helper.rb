module ApplicationHelper
  def plate_badge(plate)
    tag.span class: "plate-badge" do
      tag.span("", class: "plate-badge__band") + tag.span(plate, class: "plate-badge__text")
    end
  end
end
