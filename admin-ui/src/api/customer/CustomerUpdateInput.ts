import { AddressWhereUniqueInput } from "../address/AddressWhereUniqueInput";
import { OrderWhereUniqueInput } from "../order/OrderWhereUniqueInput";
import { OrderUpdateManyWithoutCustomersInput } from "./OrderUpdateManyWithoutCustomersInput";

export type CustomerUpdateInput = {
  address?: AddressWhereUniqueInput | null;
  email?: string | null;
  firstName?: string | null;
  lastName?: string | null;
  location?: OrderWhereUniqueInput | null;
  orders?: OrderUpdateManyWithoutCustomersInput;
  phone?: string | null;
};
