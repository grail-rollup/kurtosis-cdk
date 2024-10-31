service_package = import_module("../../lib/service.star")

PANOPTICHAIN_IMAGE = "minhdvu/panoptichain:0.1.62"


def run(plan, args):
    panoptichain_config_artifact = get_panoptichain_config(plan, args)
    plan.add_service(
        name="panoptichain" + args["deployment_suffix"],
        config=ServiceConfig(
            image=PANOPTICHAIN_IMAGE,
            ports={
                "prometheus": PortSpec(9090, application_protocol="http"),
            },
            files={"/etc/panoptichain": panoptichain_config_artifact},
        ),
    )


def get_panoptichain_config(plan, args):
    panoptichain_config_template = read_file(
        src="../../static_files/additional_services/panoptichain-config/config.yml"
    )
    contract_setup_addresses = service_package.get_contract_setup_addresses(plan, args)
    l2_rpc_url = service_package.get_l2_rpc_url(plan, args)

    # Ensure that the `l2_accounts_to_fund` parameter is > 0 or else the l2 time
    # to mine provider will fail.
    panoptichain_data = {
        "l2_rpc_url": l2_rpc_url.http,
        # cast wallet private-key "{{.l1_preallocated_mnemonic}}"
        "l1_sender_address": "0x8943545177806ED17B9F23F0a21ee5948eCaa776",
        "l2_sender_address": "0x8943545177806ED17B9F23F0a21ee5948eCaa776",
        # cast wallet address --mnemonic "{{.l1_preallocated_mnemonic}}" | cut -c3-
        "l1_sender_private_key": "bcdf20249abf0ed6d944c0288fad489e33f66b3960d9e6229c1cd214ed3bbe31",
        "l2_sender_private_key": "bcdf20249abf0ed6d944c0288fad489e33f66b3960d9e6229c1cd214ed3bbe31",
        # cast wallet address --mnemonic "code code code code code code code code code code code quality"
        "l1_receiver_address": "0x85dA99c8a7C2C95964c8EfD687E95E632Fc533D6",
        "l2_receiver_address": "0x85dA99c8a7C2C95964c8EfD687E95E632Fc533D6",
    }

    return plan.render_templates(
        name="panoptichain-config",
        config={
            "config.yml": struct(
                template=panoptichain_config_template,
                data=panoptichain_data | args | contract_setup_addresses,
            )
        },
    )
