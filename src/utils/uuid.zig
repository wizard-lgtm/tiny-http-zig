const uuid = @import("uuid");

pub fn generate_uuid() *const [36]u8 {
    const id = uuid.v7.new();
    const urn = uuid.urn.serialize(id);

    return &urn;
}
