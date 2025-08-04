module OpenProject::Patches::PrawnBadgePatch
  def fragment_measurements=(fragment)
    super

    # If the fragment is a badge, we need to adjust the line height
    callbacks = fragment.callback_objects
    callbacks.each do |obj|
      if obj.respond_to?(:badge_line_height)
        fragment.line_height = obj.badge_line_height
      end
    end
  end
end

Prawn::Text::Formatted::Arranger.prepend(OpenProject::Patches::PrawnBadgePatch)
