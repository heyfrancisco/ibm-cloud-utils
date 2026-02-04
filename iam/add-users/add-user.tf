data "ibm_iam_access_group" "access-group" {
  access_group_name = var.ag
}

resource "ibm_iam_user_invite" "invite_user" {
  users         = ["francisco.ramos.do.o@ibm.com"]
  access_groups = [data.ibm_iam_access_group.access-group.id]
}
