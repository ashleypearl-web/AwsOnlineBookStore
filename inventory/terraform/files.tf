
/*
 * Specifications: output 2 files
 *   ../server/pyconfig.json containing the Python configuration for the server.
 *      The variables are
 *          region, aws_user_id, aws_secret_key, service_port, covers_url
 *    file permissions: 0400
 *
 *   ../ansible/inventory.ini
 *    variable for the private key
 *    section inventory, entry is the AWS instance public IP
 *
 */

