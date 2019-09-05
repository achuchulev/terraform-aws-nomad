ui_url = attribute(
    "ui_url",
    description: "UI URL"
)

describe http("#{ui_url}/ui/jobs") do
    its('status') { should cmp 200 }
end