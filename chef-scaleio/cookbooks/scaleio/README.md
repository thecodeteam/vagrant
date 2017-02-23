# ScaleIO Cookbook

A Chef Cookbook for EMC ScaleIO Software Defined Storage

## Requirements

### Platforms

- Redhat Enterprise Linux
- CentOS Linux

### Chef

- Chef 12.0 or later

### Cookbooks

## Attributes

### scaleio::default

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['scaleio']['bacon']</tt></td>
    <td>Boolean</td>
    <td>whether to include bacon</td>
    <td><tt>true</tt></td>
  </tr>
</table>

## Usage

### scaleio::default

TODO: Write usage instructions for each cookbook.

e.g.
Just include `scaleio` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[scaleio]"
  ]
}
```

## Contributing

1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

## License and Authors

Authors: Aaron Spiegel <spiegela@gmail.com>

