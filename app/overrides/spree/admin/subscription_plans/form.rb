Deface::Override.new(
  virtual_path: 'spree/admin/subscription_plans/_form',
  name: 'Add plan owner and vendor policy fields',
  insert_before: 'div[data-hook="admin_subscription_plan_form_fields"]',
  text: <<-HTML
      <div data-hook="admin_subscription_plan_form_policy">
        <%= f.field_container :plan_owner_policy_id, class: ['form-group'] do %>
          <%= f.label :plan_owner_policy_id, Spree.t(:plan_owner_policy) %>
          <%= f.collection_select(:plan_owner_policy_id, @plan_owner_policies, :id, :name, { include_blank: Spree.t('match_choices.none') }, { class: 'select2' }) %>
          <%= f.error_message_on :plan_owner_policy_id %>
        <% end %>
      </div>
    HTML
)
